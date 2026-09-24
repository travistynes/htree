{-# LANGUAGE QuasiQuotes #-}

module Main (main) where

import System.Environment (getEnv)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString as BS
import Logging
import System.Log.Logger (Priority(..))
import qualified Fmt as Fmt
import qualified Configuration.Dotenv as Dotenv
import Configuration.Dotenv (Config(..))
import Database.SQLite.Simple
import Database.SQLite.Simple.FromRow

main :: IO ()
main = do
    initLogging
    loadConfig

    dbFile <- getEnv "DB_FILE"
    conn <- open dbFile
    loggit DEBUG $ Fmt.format "Opened database file: {}" dbFile

    -- Create main table, if necessary
    dbSchema <- getEnv "DB_SCHEMA"
    sqlCreateTable <- readFileUtf8 dbSchema
    execute_ conn (Query sqlCreateTable)

    close conn
    loggit DEBUG $ Fmt.format "Closed database."

loadConfig :: IO ()
loadConfig = do
    let config = Config {
            configPath = ["config/htree.env"],
            configExamplePath = [],
            configOverride = False,
            configVerbose = False, -- Print loaded env vars
            configDryRun = False,
            allowDuplicates = False
        }

    Dotenv.loadFile config

{-
Read a file known to be UTF-8 encoded as Text.

Using ByteString.readFile + decodeUtf8 is preferred over
Data.Text.IO.readFile because the latter is locale-dependent
and can be slower due to encoding conversions.
 -}
readFileUtf8 :: String -> IO T.Text
readFileUtf8 filePath = TE.decodeUtf8 <$> BS.readFile filePath
