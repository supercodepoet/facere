class TodoItem < ApplicationRecord
  STATUSES = %w[todo in_progress on_hold done].freeze
  PRIORITIES = %w[none low medium high urgent].freeze
  PRIORITY_COLORS = {
    "none" => "#A1A1AA", "low" => "#14B8A6", "medium" => "#3B82F6",
    "high" => "#F59E0B", "urgent" => "#EF4444"
  }.freeze
  PRIORITY_BG_COLORS = {
    "none" => nil, "low" => "#F0FDFA", "medium" => "#EFF6FF",
    "high" => "#FEF3C7", "urgent" => "#FEE2E2"
  }.freeze
  STATUS_COLORS = {
    "todo" => "#A1A1AA", "in_progress" => "#8B5CF6",
    "on_hold" => "#F59E0B", "done" => "#14B8A6"
  }.freeze
  STATUS_LABELS = {
    "todo" => "To Do", "in_progress" => "In Progress",
    "on_hold" => "On Hold", "done" => "Done"
  }.freeze
  PRIORITY_LABELS = {
    "none" => "None", "low" => "Low", "medium" => "Medium",
    "high" => "High", "urgent" => "Urgent"
  }.freeze

  belongs_to :todo_list
  belongs_to :todo_section, optional: true

  has_many :item_assignees, dependent: :destroy
  has_many :assignees, through: :item_assignees, source: :user
  has_many :checklist_items, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :item_tags, dependent: :destroy
  has_many :tags, through: :item_tags
  has_many :notify_people, dependent: :destroy

  has_rich_text :notes
  has_many_attached :files

  validates :name, presence: true, length: { maximum: 255 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }

  scope :active, -> { where(archived: false) }
  scope :archived_items, -> { where(archived: true) }
  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
  scope :overdue, -> { where("due_date < ?", Date.current).where(completed: false) }
  default_scope { order(:position) }

  after_create_commit -> { broadcast_refresh_to [ todo_list, :updates ] }
  after_update_commit -> { broadcast_refresh_to [ todo_list, :updates ] }
  after_destroy_commit -> { broadcast_refresh_to [ todo_list, :updates ] }

  before_save :sync_completion_and_status
  after_save :send_completion_notifications

  def toggle_completion!
    update!(completed: !completed)
  end

  def archive!
    update!(archived: true)
  end

  def move_to(section_id:, position:)
    update!(todo_section_id: section_id, position: position)
  end

  def duplicate_to(section_id:, position:)
    duplicate = dup
    duplicate.assign_attributes(todo_section_id: section_id, position: position)
    duplicate.save!
    duplicate
  end

  def overdue?
    due_date.present? && due_date < Date.current && !completed?
  end

  def due_date_style
    return nil if due_date.blank?
    return "danger" if due_date < Date.current
    return "warning" if due_date <= 3.days.from_now.to_date
    return "info" if due_date <= 14.days.from_now.to_date

    "success"
  end

  def priority_color
    PRIORITY_COLORS[priority]
  end

  def priority_bg_color
    PRIORITY_BG_COLORS[priority]
  end

  def status_color
    STATUS_COLORS[status]
  end

  def status_label
    STATUS_LABELS[status]
  end

  def priority_label
    PRIORITY_LABELS[priority]
  end

  def due_date_display
    return nil if due_date.blank?

    due_date.strftime("%B %-d, %Y")
  end

  def due_date_countdown
    return nil if due_date.blank?

    days = (due_date - Date.current).to_i
    if days > 0
      "#{days} #{"day".pluralize(days)} left"
    elsif days == 0
      "Due today"
    else
      "#{days.abs} #{"day".pluralize(days.abs)} overdue"
    end
  end

  def due_date_countdown_color
    return nil if due_date.blank?

    days = (due_date - Date.current).to_i
    days < 0 ? "#EF4444" : "#F59E0B"
  end

  def checklist_progress
    total = checklist_items.size
    return "0/0" if total == 0

    done = checklist_items.count(&:completed?)
    "#{done}/#{total}"
  end

  def file_type_icon(blob)
    content_type = blob.content_type.to_s
    case content_type
    when /image/ then "image"
    when /pdf/, /document/, /msword/, /text/ then "file-lines"
    when /spreadsheet/, /excel/, /csv/ then "file-excel"
    else "file"
    end
  end

  def file_type_color(blob)
    content_type = blob.content_type.to_s
    case content_type
    when /image/ then "#F472B6"
    when /pdf/, /document/, /msword/, /text/ then "#8B5CF6"
    when /spreadsheet/, /excel/, /csv/ then "#14B8A6"
    else "#71717A"
    end
  end

  private

  def send_completion_notifications
    return unless saved_change_to_completed? && completed?
    return unless Current.user

    notify_people.includes(:user).each do |notify_person|
      CollaborationMailer.item_completed_email(self, Current.user, notify_person.user).deliver_later
    end
  end

  def sync_completion_and_status
    if completed_changed?
      self.status = completed? ? "done" : "todo"
    elsif status_changed?
      self.completed = (status == "done")
    end
  end
end
