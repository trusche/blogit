module Blogit
  class Post < ActiveRecord::Base

    require 'acts-as-taggable-on'
    require "kaminari"

    include ::ActionView::Helpers::TextHelper

    acts_as_taggable

    self.paginates_per Blogit.configuration.posts_per_page

    AVAILABLE_STATUS = (Blogit.configuration.hidden_states + Blogit.configuration.active_states)


    # ===============
    # = Validations =
    # ===============

    validates :title, presence: true, length: { minimum: 10, maximum: 66 }

    validates :body,  presence: true, length: { minimum: 10 }
    
    validates :description, presence: Blogit.configuration.show_post_description

    validates :blogger_id, presence: true

    validates :state, presence: true

    # ================
    # = Associations =
    # ================

    ##
    # The blogger (User, Admin, etc.) who wrote this Post
    #
    # Returns a Blogger (polymorphic type)
    belongs_to :blogger, :polymorphic => true

    ##
    # The {Comment Comments} written on this Post
    #
    # Returns an ActiveRecord::Relation instance
    has_many :comments, :class_name => "Blogit::Comment"

    # ==========
    # = Scopes =
    # ==========

    scope :for_index, lambda { |page_no = 1| 
      active.order("created_at DESC").page(page_no) }
      
    scope :active, lambda { where(state:  Blogit.configuration.active_states ) }


    # The posts to be displayed for RSS and XML feeds/sitemaps
    #
    # Returns an ActiveRecord::Relation
    def self.for_feed
      active.order('created_at DESC')
    end
    
    # Finds an active post with given id
    #
    # id - The id of the Post to find
    #
    # Returns a Blogit::Post
    # Raises ActiveRecord::NoMethodError if no Blogit::Post could be found
    def self.active_with_id(id)
      active.find(id)
    end
    
    # ====================
    # = Instance Methods =
    # ====================

    # TODO: Get published at working properly!
    def published_at
      created_at
    end
    
    def to_param
      "#{id}-#{title.parameterize}"
    end
    
    def short_body
      truncate(body, length: 400, separator: "\n")
    end
    
    def comments
      check_comments_config
      super()
    end
    
    def comments=(value)
      check_comments_config
      super(value)
    end
    

    # The blogger who wrote this {Post Post's} display name
    #
    # Returns the blogger's display name as a String if it's set.
    # Returns an empty String if blogger is not present.
    # Raises a ConfigurationError if the method called is not defined on {#blogger}
    def blogger_display_name
      if self.blogger and !self.blogger.respond_to?(Blogit.configuration.blogger_display_name_method)
        raise ConfigurationError,
        "#{self.blogger.class}##{Blogit.configuration.blogger_display_name_method} is not defined"
      elsif self.blogger.nil?
        ""
      else
        blogger.send(Blogit.configuration.blogger_display_name_method)
      end
    end

    # If there's a blogger and that blogger responds to :twitter_username, returns that.
    # Otherwise, returns nil
    def blogger_twitter_username
      if blogger and blogger.respond_to?(:twitter_username)
        blogger.twitter_username
      end
    end
    

    private


    def check_comments_config
      raise RuntimeError.new("Posts only allow active record comments (check blogit configuration)") unless Blogit.configuration.include_comments == :active_record
    end
    
  end
end