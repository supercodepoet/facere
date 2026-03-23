class CollaborationMailer < ApplicationMailer
  def invitation_email(invitation)
    @invitation = invitation
    @todo_list = invitation.todo_list
    @inviter = invitation.invited_by
    @accept_url = accept_invitation_url(token: invitation.generate_token_for(:acceptance))

    mail(
      to: invitation.email,
      subject: "#{@inviter.name} invited you to collaborate on \"#{@todo_list.name}\" in Facere"
    )
  end

  def item_completed_email(todo_item, completed_by, recipient)
    @todo_item = todo_item
    @completed_by = completed_by
    @recipient = recipient
    @todo_list = todo_item.todo_list
    @item_url = todo_list_todo_item_url(@todo_list, @todo_item)

    mail(
      to: recipient.email_address,
      subject: "\"#{@todo_item.name}\" was completed in \"#{@todo_list.name}\""
    )
  end
end
