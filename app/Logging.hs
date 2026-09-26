module Logging (initLogging, loggit, Priority(..)) where

import System.Log.Logger
import System.Log.Handler.Simple (streamHandler)
import qualified System.Log.Handler as LogHandler
import System.Log.Formatter (simpleLogFormatter)
import System.IO (stdout)

loggerName :: String
loggerName = "app.main"

initLogging :: IO ()
initLogging = do
    -- Remove the root logger's handler or it will also log messages from other loggers
    -- ie. duplicate log messages will be logged
    updateGlobalLogger rootLoggerName removeHandler

    handler <- streamHandler stdout DEBUG
        >>= \h -> pure $ LogHandler.setFormatter h (simpleLogFormatter "[$time - $loggername ($prio)] $msg")
    updateGlobalLogger loggerName (setLevel DEBUG . setHandlers [handler])

-- Log message at the given priority (DEBUG, INFO, WARNING, ERROR, etc.)
loggit :: Priority -> String -> IO ()
loggit p msg = logM loggerName p msg
