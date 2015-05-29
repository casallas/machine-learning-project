function countdown()
  displayHUD("3", Vec{0, 1.5, -10})
  Actions.waitSeconds(1)
  displayHUD("2", Vec{0, 1.5, -10})
  Actions.waitSeconds(1)
  displayHUD("1", Vec{0, 1.5, -10})
  Actions.waitSeconds(1)
end

