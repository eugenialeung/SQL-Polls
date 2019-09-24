# == Schema Information
#
# Table name: responses
#
#  id               :bigint           not null, primary key
#  answer_choice_id :integer          not null
#  respondent_id    :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Response < ApplicationRecord
    belongs_to :answer_choice,
        primary_key: :id,
        foreign_key: :answer_choice_id,
        class_name: 'AnswerChoice'
    

    belongs_to :respondent,
        primary_key: :id,
        foreign_key: :respondent_id,
        class_name: 'User'

    has_one :question,
        through: :answer_choice,
        source: :question

    # Only run validation if there is an answer_choice that exists
    # (otherwise this validation raises an error)
    validate :not_duplicate_response, unless: -> { answer_choice.nil? }

    # Only run validation if answer_choice exists
    # If answer_choice existence isn't checked, we will incorrectly get an error
    # "Respondent cannot be poll author" when no repondent is provided
    # or won't have an error when we set respondent to the poll author
    # until a answer_choice is set
    validate :respondent_is_not_poll_author, unless: -> { answer_choice.nil? }

    def sibling_responses
        # 2-query way
        self.question.responses.where.not(id: self.id)
    end

    def respondent_already_answered?
        sibling_responses.exists?(respondent_id: self.respondent_id)
    end


    private

    def respondent_is_not_poll_author
        # The 3-query slow way:
        # poll_author_id = self.answer_choice.question.poll.author_id
    
        # 1-query; joins two extra tables.
        poll_author_id = Poll
          .joins(questions: :answer_choices)
          .where('answer_choices.id = ?', self.answer_choice_id)
          .pluck('polls.author_id')
          .first
    
        if poll_author_id == self.respondent_id
          errors[:respondent_id] << 'cannot be poll author'
        end
    end

    def not_duplicate_response
        if respondent_already_answered?
          errors[:respondent_id] << 'cannot vote twice for question'
        end
    end
end
