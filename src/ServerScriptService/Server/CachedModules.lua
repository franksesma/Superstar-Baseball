--!strict

export type CachedModules = {
	Cache: {[string]: any},
	CacheLoaded: boolean,
}

local CachedModules: CachedModules = {
	Cache = {},
	CacheLoaded = false,
}

return CachedModules
