class Order < ActiveRecord::Base

	STATUSES = %w[Unapproved Unclaimed Claimed Started Proofing Revising Complete]
	TYPES = %w[Graphics Web]
	self.per_page = 20

	after_initialize :setup_order

	belongs_to :owner, class_name: 'User'
	belongs_to :creative, class_name: 'User'
	belongs_to :organization


	validates :name, :due, :description, :needs, presence: true

	scope :readable, -> (user) {
		where("owner_id = ? OR creative_id = ? OR (status = 'Unclaimed' AND
		flavor = ?) OR organization_id IN (?)", user.id, user.id, user.flavor,
		user.assignments.advised.pluck(:organization_id))
	}

	scope :completed, -> (user) { where(status: "Complete").where("owner_id = ? OR
		creative_id = ? OR organization_id IN (?)", user.id, user.id,
		user.assignments.advised.pluck(:organization_id)) }

	class << self
		def graphics_needs
			["Poster", "A-Frame", "T-Shirt", "Logo", "Brochure", "Program",
			 "FB Event Photo", "FB Cover Photo", "FB Profile Photo", "Palm Card",
			 "Other"]
		end


		def web_needs
			["New Event Site", "New Org Site", "Re-Brand", "Change Text",
			 "Change Media", "Change Layout", "Change Design", "New Feature",
			 "Other"]
		end


		def statuses
			STATUSES[3..6]
		end
	end


	def readable? user
		readable ||= !owner.nil? && owner == user
		readable ||= !creative.nil? && creative == user
		readable ||= user.role == "Creative" && status == "Unclaimed" && flavor == user.flavor
		readable ||= !organization.nil? &&
			organization_id.in?(user.assignments.advised.pluck(:organization_id))
	end


	def validate_due_date
		return_value = true

		unless due.present? && due >= Date.today + 2.weeks
			errors.add :due, "date must be at least two weeks away."
			return_value = false
		end

		if due.saturday? || due.sunday?
			errors.add :due, "date shouldn't be on a weekend."
			return_value = false
		end

		return return_value
	end


	def due_date
		return due.strftime("%A, %B #{due.day.ordinalize}")
	end


	def hsl
		hue = [[(due - Date.today).to_f / 14.0 * 75 + 25, 100].min, 25].max
		saturation = "100%"
		lightness = "#{50.0 - 10 * (hue - 50).abs / 50.0}%"

		return "hsl(" + hue.to_s + ", " + saturation + ", " + lightness + ")"
	end


	def setup_order
		self.status ||= STATUSES[0]
		self.event ||= {}
		self.needs ||= {}
		# self.flavor ||= "Graphics"
	end
end