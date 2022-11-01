local cvars_AddChangeCallback = cvars.AddChangeCallback
local engine_GetAddons = engine.GetAddons
local timer_Simple = timer.Simple
local isfunction = isfunction
local isstring = isstring
local assert = assert
local ipairs = ipairs
local pairs = pairs
local MsgC = MsgC

local resource = resource
local string = string
local table = table
local game = game
local math = math

local cvar = CreateConVar( 'sv_workshop_dl', '1', FCVAR_ARCHIVE, ' - Enables automatic adding addons to Workshop DL.', 0, 1 )

local color0 = Color( 0, 175, 255 )
local color1 = Color( 220, 220, 220 )

module( 'awdl' )

function Log( str )
    MsgC( color0, '[Automatic Workshop DL] ', color1, str, '\n' )
end

do

    local addons = {}
    local count = 0

    function GetTable()
        return addons
    end

    function GetCount()
        return count
    end

    function IsInstalled( wsid )
        assert( isstring( wsid ), 'Argument #1 must be a string!' )
        return addons[ wsid ] or false
    end

    function Add( wsid, addon )
        assert( isstring( wsid ), 'Argument #1 must be a string!' )
        resource.AddWorkshop( wsid )
        addons[ wsid ] = addon
        count = count + 1

        Log( '+ ' .. addon.title .. ' [' .. math.Round( addon.size / 1024 / 1024, 2 ) .. 'MB]' )
    end

end

do

    local gmodFolders = {
        'materials',
        'particles',
        'resource',
        'models',
        'sound',
        'maps'
    }

    function Init()
        Log( 'Beginning of the processing of server addons.' )

        local addons = {}
        for num, addon in ipairs( engine_GetAddons() ) do
            if IsInstalled( addon.wsid ) then continue end
            if addon.downloaded and addon.mounted then
                table.insert( addons, addon )
            end
        end

        local count = #addons
        if (count < 1) then
            Log( 'Detected ' .. count .. ' addons, processing is not required.' )
            return
        end

        Log( 'Detected ' .. count .. ' addons, processing...' )

        local currentMap = game.GetMap()
        local addonsCount = GetCount()

        for num, addon in ipairs( addons ) do
            local ok, files = game.MountGMA( addon.file )
            if (ok) then
                if string.match( addon.tags, 'map' ) then
                    for num, fl in ipairs( files ) do
                        if string.sub( fl, #fl - 3, #fl ) == '.bsp' and string.sub( fl, 6, #fl - 4 ) == currentMap then
                            Add( addon.wsid, table.Merge( addon, {['files'] = files}) )
                            break
                        end
                    end

                    continue
                end

                for num, fl in ipairs( files ) do
                    local haveResources = false
                    for num, fol in ipairs( gmodFolders ) do
                        if string.StartWith( fl, fol .. '/' ) then
                            Add( addon.wsid, table.Merge( addon, {['files'] = files}) )
                            haveResources = true
                            break
                        end
                    end

                    if (haveResources) then
                        break
                    end
                end
            end
        end

        Log( (GetCount() - addonsCount) .. ' addons successfully added to WorkshopDL.' )
    end

end

timer_Simple(0, function()

    if cvar:GetBool() then
        Init()
    end

    cvars_AddChangeCallback(cvar:GetName(), function( _, __, new )
        if (new == '1') then
            Init()
        elseif isfunction( resource.RemoveWorkshop ) then
            local addons = {}
            local dataTable = GetTable()
            for wsid, data in pairs( dataTable ) do
                table.insert( addons, wsid )
                dataTable[ wsid ] = nil
            end

            resource.RemoveWorkshop( addons )
        end
    end)

end)
