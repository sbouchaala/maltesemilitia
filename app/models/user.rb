class User < ActiveRecord::Base
    require 'mailchimp'
    belongs_to :referrer, :class_name => "User", :foreign_key => "referrer_id"
    has_many :referrals, :class_name => "User", :foreign_key => "referrer_id"
    
    attr_accessible :email

    validates :email, :uniqueness => true, :format => { :with => /\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/i, :message => "Invalid email format." }
    validates :referral_code, :uniqueness => true

    before_create :create_referral_code
    after_create :update_referral_count
    after_create :mail_chimp_sync
    REFERRAL_STEPS = [
        {
            'count' => 5,
            "html" => "Stickers",
            "class" => "two",
            "image" =>  ActionController::Base.helpers.asset_path("refer/Stickers.jpg"),
            "fslide" => ActionController::Base.helpers.asset_path("refer/stickers/stickers-1.jpg")
        },
        {
            'count' => 10,
            "html" => "Wrist Wraps",
            "class" => "three",
            "image" => ActionController::Base.helpers.asset_path("refer/wrist-wraps.jpg"),
            "fslide" => ActionController::Base.helpers.asset_path("refer/wrist-wraps/wrist-wraps-1.jpg")
        },
        {
            'count' => 25,
            "html" => "T-Shirt",
            "class" => "four",
            "image" => ActionController::Base.helpers.asset_path("refer/Tshirt.jpg"),
            "fslide" => ActionController::Base.helpers.asset_path("refer/t-shirt/t-shirt-1.jpg")
        },
        {
            'count' => 50,
            "html" => "Hat & Bandana",
            "class" => "five",
            "image" => ActionController::Base.helpers.asset_path("refer/hat+bandana.jpg"),
            "fslide" => ActionController::Base.helpers.asset_path("refer/hat-bandana/bandana-1.jpg")
        }
    ]

    def display_name
      self.email
    end

    private
    def update_referral_count
      if self.referrer
        if self.referrer.referred
          self.referrer.referred +=1
        else
          self.referrer.referred = 1
        end
        self.referrer.save
        update_mailchimp_referred
      end
    end

    def create_referral_code
        referral_code = SecureRandom.hex(5)
        @collision = User.find_by_referral_code(referral_code)

        while !@collision.nil?
            referral_code = SecureRandom.hex(5)
            @collision = User.find_by_referral_code(referral_code)
        end

        self.referral_code = referral_code
        self.referred = 0
    end

    def mail_chimp_sync
      begin
        @mc = Mailchimp::API.new('API-KEY')
        @mc.lists.subscribe('LIST-ID', {'email' => self.email}, {'FIELD-NAME'=>self.referral_code}, 'html', false,true)
        logger.debug "#{self.email} subscribed successfully"
      rescue Mailchimp::ListAlreadySubscribedError
        logger.debug "#{self.email} is already subscribed to the list"
      rescue Mailchimp::ListDoesNotExistError
        logger.debug "The list could not be found"
        return
      rescue Mailchimp::Error => ex
        if ex.message
          logger.debug ex.message
        else
          logger.debug "An unknown error occurred"
        end
      end
    end

    def update_mailchimp_referred
      begin
        @mc = Mailchimp::API.new('API-KEY')
        @mc.lists.subscribe('LIST-ID', {'email' => self.referrer.email}, {'FIELD-NAME'=>self.referrer.referred}, 'html', false,true)
        logger.debug "#{self.referrer.email} subscribed successfully"
      rescue Mailchimp::ListAlreadySubscribedError
        logger.debug "#{self.referrer.email} is already subscribed to the list"
      rescue Mailchimp::ListDoesNotExistError
        logger.debug "The list could not be found"
        return
      rescue Mailchimp::Error => ex
        if ex.message
          logger.debug ex.message
        else
          logger.debug "An unknown error occurred"
        end
      end
    end
end
