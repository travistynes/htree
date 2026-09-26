module Main (main) where

import System.Environment (getArgs, getEnv)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString as BS
import Logging
import qualified Fmt as Fmt
import qualified Configuration.Dotenv as Dotenv
import Configuration.Dotenv (Config(..))
import Database.SQLite.Simple
import Control.Monad (forM_)

data HtreeRow = HtreeRow {
    htId :: Int,
    htName :: String,
    htDescription :: Maybe String,
    htDt :: Maybe String,
    htParentId :: Maybe Int,
    htCreatedDt :: String
} deriving Show

instance FromRow HtreeRow where
    fromRow = HtreeRow <$> field <*> field <*> field <*> field <*> field <*> field

main :: IO ()
main = do
    initLogging
    loadConfig

    -- Get db connection
    dbFile <- getEnv "DB_FILE"
    conn <- open dbFile
    loggit DEBUG $ Fmt.format "Opened database: {}" dbFile

    -- Create main table, if necessary
    dbSchema <- getEnv "DB_SCHEMA"
    sqlCreateTable <- readFileUtf8 dbSchema
    execute_ conn (Query sqlCreateTable)

    args <- getArgs
    case args of
        [] -> putStrLn "Missing required arguments. Try --help"
        ("--help":_) -> putStrLn "Help description"
        ("--search":name:_) -> searchItem conn name
        ("--id":itemId:_) -> getItem conn (read itemId :: Int)
        ("--add":name:xs) -> addItem conn name xs
        ("--delete":itemId:_) -> putStrLn $ "Delete: " ++ show itemId
        ("--move":itemId:parentId:_) -> putStrLn $ "Move " ++ show itemId ++ " to parent id " ++ show parentId
        (_:_) -> putStrLn "Unrecognized arguments"

    -- Close db connection
    close conn
    loggit DEBUG $ Fmt.format "Closed database."

searchItem :: Connection -> String -> IO ()
searchItem conn name = do
    sqlSearch <- readFileUtf8 "sql/searchByName.sql"
    rows <- query conn (Query sqlSearch) [name] :: IO [Only T.Text]

    case rows of
        [] -> putStrLn "No data."
        (_:_) ->
            forM_ rows $ \(Only r) ->
                putStrLn $ T.unpack r

getItem :: Connection -> Int -> IO ()
getItem conn itemId = do
    sql <- readFileUtf8 "sql/getItemById.sql"
    rows <- query conn (Query sql) [itemId] :: IO [Only T.Text]

    case rows of
        [] -> putStrLn "No data."
        (_:_) ->
            forM_ rows $ \(Only r) ->
                putStrLn $ T.unpack r

addItem :: Connection -> String -> [String] -> IO ()
addItem conn name args = do
    let sql = "insert into item (name, description, dt, parent_id) values (?, ?, ?, ?)"
    let description = getArg "--description" args
    let dt = getArg "--dt" args
    let parentId = (read <$> getArg "--parent" args) :: Maybe Int
    execute conn sql (name, description, dt, parentId)
    loggit DEBUG $ Fmt.format "Added item: {}" name

getArg :: String -> [String] -> Maybe String
getArg _ [] = Nothing
getArg _ [_] = Nothing
getArg arg (k:v:xs) | arg == k = Just v | otherwise = getArg arg xs

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
