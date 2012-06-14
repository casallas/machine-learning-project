-- Look for models in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our models!")
vrjLua.appendToModelSearchPath(fn)

colWavPath = vrjLua.findInModelSearchPath("sound/piuf.wav")

--OpenAL allows us to spatialize the sound
snx.changeAPI("OpenAL")

--create a sound info object
soundInfo = snx.SoundInfo()

-- set the filename attribute of the soundFile
soundInfo.filename = colWavPath
--create a new sound handle and pass it the filename from the soundInfo object
soundHandle = snx.SoundHandle(soundInfo.filename)
--configure the soundHandle to use the soundInfo
soundHandle:configure(soundInfo)

-- pos 3-slot array with the position to play the collision sound, by default it's the origin
function playCollisionSound( pos )
	pos = pos or {0,0,0}
	if soundHandle.isPlaying then
		soundHandle:stop()
	end
	soundHandle:setPosition(pos[1],pos[2],pos[3])
	soundHandle:trigger(1)
end
