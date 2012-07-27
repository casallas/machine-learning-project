-- Look for models in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our models!")
vrjLua.appendToModelSearchPath(fn)

colWavPath = vrjLua.findInModelSearchPath("sound/piuf.wav")

passWavPath = vrjLua.findInModelSearchPath("sound/bouit.wav")

--OpenAL allows us to spatialize the sound
snx.changeAPI("OpenAL")

--create a sound info object
colSoundInfo = snx.SoundInfo()
passSoundInfo = snx.SoundInfo()

-- set the filename attribute of the soundFile
colSoundInfo.filename = colWavPath
passSoundInfo.filename = passWavPath

--create a new sound handle and pass it the filename from the soundInfo object
colSoundHandle = snx.SoundHandle(colSoundInfo.filename)
passSoundHandle = snx.SoundHandle(passSoundInfo.filename)
--configure the soundHandle to use the soundInfo
colSoundHandle:configure(colSoundInfo)
passSoundHandle:configure(passSoundInfo)

-- pos 3-slot array with the position to play the collision sound, by default it's the origin
function playCollisionSound( pos )
	pos = pos or {0,0,0}
	if colSoundHandle.isPlaying then
		colSoundHandle:stop()
	end
	colSoundHandle:setPosition(pos[1],pos[2],pos[3])
	colSoundHandle:trigger(1)
end

-- pos 3-slot array with the position to play the collision sound, by default it's the origin
function playPassSound( pos )
	pos = pos or {0,0,0}
	if passSoundHandle.isPlaying then
		passSoundHandle:stop()
	end
	passSoundHandle:setPosition(pos[1],pos[2],pos[3])
	passSoundHandle:trigger(1)
end
