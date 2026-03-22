class TodoItem < ApplicationRecord
  STATUSES = %w[todo in_progress done].freeze
  PRIORITIES = %w[none low medium high].freeze
  PRIORITY_COLORS = { "none" => nil, "low" => "teal", "medium" => "orange", "high" => "danger" }.freeze

  belongs_to :todo_list
  belongs_to :todo_section, optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  has_many :checklist_items, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :item_tags, dependent: :destroy
  has_many :tags, through: :item_tags

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

  before_save :sync_completion_and_status

  def toggle_completion!
    update!(completed: !completed)
  end

  def archive!
    update!(archived: true)
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

  private

  def sync_completion_and_status
    if completed_changed?
      self.status = completed? ? "done" : "todo"
    elsif status_changed?
      self.completed = (status == "done")
    end
  end
end
