local function exec(prog)
    print('#Execute', prog)
    local result = io.popen(prog):read('*a')
    print(result)
    return result
end

local function merge(pathDst, urlDst, urlSrc, revRanges, accept)
    exec('svn revert -R '..pathDst)
    exec('svn switch '..urlDst..' '..pathDst)
    exec('svn up '..pathDst)

    local prog = 'svn merge --accept '..(accept or 'p')..' '..urlSrc..' '..pathDst
    if revRanges and type(revRanges) == 'table' and #revRanges > 0 then
        for _,rev in ipairs(revRanges) do
            if type(rev) == 'number' then
                prog = prog..' -c '..rev
            elseif type(rev) == 'string' then
                prog = prog..' -r '..rev
            end
        end
    end

    local result = exec(prog)
    local matched = {}
    for cap in string.gmatch(result, 'Merging (r%d+ through r%d+) into') do
        table.insert(matched, cap)
    end
    for cap in string.gmatch(result, 'Merging (r%d+) into') do
        table.insert(matched, cap)
    end
    return #matched > 0 and 'Merging '..table.concat(matched, ',') or nil
end

local function sync(wcPath, urlBase, srcBranch, dstBranch, revRanges, accept)
    local urlSrc = urlBase..srcBranch
    local urlDst = urlBase..dstBranch
    print(string.format('#Sync [%s] => [%s]', srcBranch, dstBranch))
    local mergeRev = merge(wcPath, urlDst, urlSrc, revRanges, accept)
    if mergeRev then
        local msg = string.format('"sync with %s, %s"', srcBranch, mergeRev)
        exec('svn commit -m '..msg..' '..wcPath)
        print('#Sync Finished')
    else
        print('#Sync Nothing')
    end
end


--[[
local WORKING_COPY_PATH = '/your/path/repo'
local SVN_URL_BASE = 'https://xxx/xxx/xxx'
local SRC_BRANCH = 'trunk'
local DST_BRANCH = 'branches/xxx'
local REVISION_RANGES = {101,102,'105-108'}
local CONFLICT_ACCEPT = 'tf'
sync(WORKING_COPY_PATH, SVN_URL_BASE, SRC_BRANCH, DST_BRANCH, REVISION_RANGES, CONFLICT_ACCEPT)
--]]
