function Player:setPremiumDays(premiumDays)
	self.premiumDays = tonumber(premiumDays)
end

function Player:getPremiumDays()
	return self.premiumDays
end
