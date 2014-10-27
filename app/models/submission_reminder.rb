# == Schema Information
#
# Table name: submission_reminders
#
#  id                              :uuid             not null, primary key
#  submission_id                   :uuid             not null
#  medium                          :text             not null
#  message                         :text
#  meta                            :hstore
#  sent                            :boolean          default(FALSE), not null
#  sent_at                         :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  submission_reminder_template_id :uuid
#

class SubmissionReminder < ActiveRecord::Base

  class << self
    def send_pending!
      pending.to_a.tap { |p| p.each &:send! }
    end
  end

  belongs_to :submission
  has_one :user, through: :submission
  belongs_to :submission_reminder_template

  store_accessor :meta, :subject, :from
  attr_accessor :template

  scope :email,   -> { where medium: 'email' }
  scope :slack,   -> { where medium: 'slack' }
  scope :sent,    -> { where sent: true }
  scope :unsent,  -> { where sent: false }
  scope :pending, -> { unsent }

  validates_presence_of :submission
  validates_presence_of :medium
  validates_presence_of :message

  validate :message_must_include_submission_url

  before_validation -> { message }

  def message
    self.message = (self[:message].presence || render_template)
  end

  def to
    "#{user.name} <#{user.email}>"
  end

  def send! *args, &block
    raise StandardError, "Set :medium before sending" if medium.blank?
    raise NotImplementedError, "Unsupported medium '#{medium}'" unless methods.include? :"send_#{medium}!"

    send(:"send_#{medium}!", *args, &block).tap do |result|
      self.sent    = true
      self.sent_at = Time.now

      save!

      result
    end
  end


  protected

  def send_email!
    SubmissionReminderMailer.reminder(self).deliver
  end

  def render_template
    Liquid::Template.parse(template).render(template_options)
  end

  def template_options
    {
      'submission' => submission,
      'user' => user,
    }
  end

  def message_must_include_submission_url
    errors.add(:message, 'is missing the submission url') unless message.to_s.include? submission.try(:url)
  end

end
