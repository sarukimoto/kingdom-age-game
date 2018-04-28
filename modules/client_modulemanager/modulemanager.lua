local moduleManagerWindow
local moduleManagerButton
local moduleList

function init()
  moduleManagerWindow = g_ui.displayUI('modulemanager')
  moduleManagerWindow:hide()
  moduleList = moduleManagerWindow:getChildById('moduleList')
  connect(moduleList, { onChildFocusChange = function(self, focusedChild)
                          if focusedChild == nil then return end
                          updateModuleInfo(focusedChild:getText())
                        end })

  g_keyboard.bindKeyPress('Up', function() moduleList:focusPreviousChild(KeyboardFocusReason) end, moduleManagerWindow)
  g_keyboard.bindKeyPress('Down', function() moduleList:focusNextChild(KeyboardFocusReason) end, moduleManagerWindow)

  --moduleManagerButton = modules.client_topmenu.addLeftButton('moduleManagerButton', tr('Module Manager') .. ' (Ctrl+Alt+T)', '/images/topbuttons/modulemanager', toggle)

  g_keyboard.bindKeyDown('Ctrl+Alt+T', toggle)

  -- refresh modules only after all modules are loaded
  addEvent(listModules)
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+Alt+T')

  moduleManagerWindow:destroy()
  if moduleManagerButton then
    moduleManagerButton:destroy()
  end
  moduleList = nil
end

function disable()
  if moduleManagerButton then
    moduleManagerButton:hide()
  end
end

function hide()
  moduleManagerWindow:hide()
  if moduleManagerButton then
    moduleManagerButton:setOn(false)
  end
end

function show()
  if not g_game.isOnline() or g_game.getAccountType() < ACCOUNT_TYPE_GAMEMASTER then return end
  moduleManagerWindow:show()
  moduleManagerWindow:raise()
  moduleManagerWindow:focus()
  if moduleManagerButton then
    moduleManagerButton:setOn(true)
  end
end

function toggle()
  if moduleManagerWindow:isVisible() then
    hide()
  else
    show()
  end
end

function refreshModules()
  g_modules.discoverModules()
  listModules()
end

function listModules()
  if not moduleManagerWindow then return end

  moduleList:destroyChildren()

  local modules = g_modules.getModules()
  for i,module in ipairs(modules) do
    local label = g_ui.createWidget('ModuleListLabel', moduleList)
    label:setText(module:getName())
    label:setOn(module:isLoaded())
  end

  moduleList:focusChild(moduleList:getFirstChild(), ActiveFocusReason)
end

function refreshLoadedModules()
  if not moduleManagerWindow then return end

  for i,child in ipairs(moduleList:getChildren()) do
    local module = g_modules.getModule(child:getText())
    child:setOn(module:isLoaded())
  end
end

function updateModuleInfo(moduleName)
  if not moduleManagerWindow then return end

  local name = ''
  local description = ''
  local autoLoad = ''
  local author = ''
  local website = ''
  local version = ''
  local loaded = false
  local canReload = false
  local canUnload = false

  local module = g_modules.getModule(moduleName)
  if module then
    name = module:getName()
    description = module:getDescription()
    author = module:getAuthor()
    website = module:getWebsite()
    version = module:getVersion()
    loaded = module:isLoaded()
    canReload = module:canReload()
    canUnload = module:canUnload()
  end

  moduleManagerWindow:recursiveGetChildById('moduleName'):setText(name)
  moduleManagerWindow:recursiveGetChildById('moduleDescription'):setText(description)
  moduleManagerWindow:recursiveGetChildById('moduleAuthor'):setText(author)
  moduleManagerWindow:recursiveGetChildById('moduleWebsite'):setText(website)
  moduleManagerWindow:recursiveGetChildById('moduleVersion'):setText(version)

  local reloadButton = moduleManagerWindow:recursiveGetChildById('moduleReloadButton')
  reloadButton:setEnabled(canReload)
  if loaded then reloadButton:setText(tr('Reload'))
  else reloadButton:setText(tr('Load')) end

  local unloadButton = moduleManagerWindow:recursiveGetChildById('moduleUnloadButton')
  unloadButton:setEnabled(canUnload)
end

function reloadCurrentModule()
  local focusedChild = moduleList:getFocusedChild()
  if focusedChild then
    local module = g_modules.getModule(focusedChild:getText())
    if module then
      module:reload()
      if modules.client_modulemanager == nil then return end
      updateModuleInfo(module:getName())
      refreshLoadedModules()
      show()
    end
  end
end

function unloadCurrentModule()
  local focusedChild = moduleList:getFocusedChild()
  if focusedChild then
    local module = g_modules.getModule(focusedChild:getText())
    if module then
      module:unload()
      if modules.client_modulemanager == nil then return end
      updateModuleInfo(module:getName())
      refreshLoadedModules()
    end
  end
end

function reloadAllModules()
  g_modules.reloadModules()
  refreshLoadedModules()
  show()
end

