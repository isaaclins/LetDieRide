function love.focus(f)
	if not f then
		print("LOST FOCUS")
	else
		print("GAINED FOCUS")
	end
end

function love.quit()
	print("Thanks for playing! Come back soon!")
end
