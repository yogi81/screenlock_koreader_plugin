local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local InputDialog = require("ui/widget/inputdialog")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local ScreenLock = WidgetContainer:extend{
    name = "screenlock_numpad_buttons",
    is_doc_only = false,

    locked   = false,      -- Track locked state
    password = "1234",     -- Your hard-coded password
    hide_content = true,   -- Hide screen content before password is entered
    current_input = "",    -- Store the current input from numpad
}

------------------------------------------------------------------------------
-- REGISTER DISPATCHER ACTIONS
------------------------------------------------------------------------------
function ScreenLock:onDispatcherRegisterActions()
    Dispatcher:registerAction("screenlock_numpad_buttons_lock_screen", {
        category = "none",
        event = "LockScreenButtons",
        title = _("Lock Screen"),
        filemanager = true,
    })
end

------------------------------------------------------------------------------
-- INIT (including wake-up handling via onResume)
------------------------------------------------------------------------------
function ScreenLock:init()
    -- 1) Register dispatcher action
    self:onDispatcherRegisterActions()
    
    -- 2) Add to main menu
    self.ui.menu:registerToMainMenu(self)

    -- 3) Override onResume to handle device wake-up
    function self:onResume()
        if not self.locked then
            self:lockScreen()
        end
    end
end

------------------------------------------------------------------------------
-- LOCK SCREEN
------------------------------------------------------------------------------
function ScreenLock:lockScreen()
    self.locked = true
    self.current_input = "" -- Reset input
    self:showNumpadPrompt()
end

------------------------------------------------------------------------------
-- SHOW NUMPAD PROMPT (USING BUTTONS ARRAY)
-- "Cancel" button reopens the prompt, preventing escape
------------------------------------------------------------------------------
function ScreenLock:showNumpadPrompt()
    local dialog
    dialog = InputDialog:new{
        title           = _("Enter Password (Numpad)"),
        input           = self.current_input, -- Show current input
        maskinput       = true,
        text_type = "password",
        hint            = _("Password"),
        fullscreen      = self.hide_content,        -- request full screen mode
        use_available_height = self.hide_content,   -- use available screen height even when keyboard is shown
        buttons         = {
            -- Numpad Buttons
            {
                {text = "1", callback = function() self:appendToInput("1", dialog) end},
                {text = "2", callback = function() self:appendToInput("2", dialog) end},
                {text = "3", callback = function() self:appendToInput("3", dialog) end},
            },
            {
                {text = "4", callback = function() self:appendToInput("4", dialog) end},
                {text = "5", callback = function() self:appendToInput("5", dialog) end},
                {text = "6", callback = function() self:appendToInput("6", dialog) end},
            },
            {
                {text = "7", callback = function() self:appendToInput("7", dialog) end},
                {text = "8", callback = function() self:appendToInput("8", dialog) end},
                {text = "9", callback = function() self:appendToInput("9", dialog) end},
            },
            {
                {text = "*", callback = function() self:appendToInput("*", dialog) end},
                {text = "0", callback = function() self:appendToInput("0", dialog) end},
                {text = "#", callback = function() self:appendToInput("#", dialog) end},
            },
            -- Action Buttons
            {
                {
                    text = _("Cancel"),
                    callback = function()
                        UIManager:show(
                            InfoMessage:new{
                                text = _("You must enter the correct password!"),
                                timeout = 1
                            }
                        )
                        UIManager:close(dialog)
                        self:lockScreen() --Relock with reset input
                    end
                },
                {
                    text = _("Clear"),
                    callback = function()
                        self.current_input = ""
                        dialog:setInputText(self.current_input)
                    end
                },
                {
                    text = _("OK"),
                    is_enter_default = true,
                    callback = function()
                        if self.current_input == self.password then
                            self.locked = false
                            UIManager:close(dialog)
                            UIManager:show(
                                InfoMessage:new{
                                    text = _("Screen unlocked."),
                                    timeout = 1
                                }
                            )
                        else
                            UIManager:show(
                                InfoMessage:new{
                                    text = _("Wrong password! Try again."),
                                    timeout = 1
                                }
                            )
                            UIManager:close(dialog)
                            self:lockScreen() --Relock with reset input
                        end
                    end
                },
            }
        },
    }
    UIManager:show(dialog)
    -- dialog:onShowKeyboard()  -- No need to open on-screen keyboard
end

------------------------------------------------------------------------------
-- Append to input
------------------------------------------------------------------------------
function ScreenLock:appendToInput(digit, dialog)
    self.current_input = self.current_input .. digit
    dialog:setInputText(self.current_input)
end

------------------------------------------------------------------------------
-- DISPATCHER HANDLER
------------------------------------------------------------------------------
function ScreenLock:onLockScreenButtons()
    self:lockScreen()
    return true
end

------------------------------------------------------------------------------
-- MAIN MENU ENTRY
------------------------------------------------------------------------------
function ScreenLock:addToMainMenu(menu_items)
   menu_items.screenlock_numpad_buttons = {
       text = _("Lock Screen"),
       callback = function()
           self:lockScreen()
       end
  }
end

return ScreenLock
