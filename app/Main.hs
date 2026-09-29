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

main :: IO ()
main = do
    initLogging
    loadConfig

    -- Get db connection
    conn <- getConnection
    --loggit DEBUG $ Fmt.format "Opened database: {}" dbFile

    -- Create main table, if necessary
    dbSchema <- getEnv "DB_SCHEMA"
    sqlCreateTable <- readFileUtf8 dbSchema
    execute_ conn (Query sqlCreateTable)

    args <- getArgs
    case args of
        [] -> putStrLn "htree: try 'htree --help' for more information"
        ("--help":xs) -> showHelp xs
        ("--roots":_) -> listRoots conn
        ("--search":name:_) -> searchItem conn name
        ("--add":name:xs) -> addItem conn name xs
        ("--delete":itemId:_) -> deleteItem conn (read itemId)
        ("--move":itemId:parentId:_) -> moveItem conn (read itemId) (read parentId)
        (_:_) -> putStrLn "Unrecognized arguments, try 'htree --help' for more information"

    -- Close db connection
    close conn
    --loggit DEBUG $ Fmt.format "Closed database."

showHelp :: [String] -> IO ()
showHelp args = do
    case args of
        [] -> do
            putStrLn "Usage: htree [options...]"
            putStrLn " --help                   Get help for commands"
            putStrLn " --add <name>             Add new item, see '--help add' for options"
            putStrLn " --delete <id>            Delete item by id, including its subtree"
            putStrLn " --move <id> <parent id>  Move item by id, including its subtree, under new parent id"
            putStrLn " --roots                  Show all top-level items"
            putStrLn " --search <name>          Find items by name or partial name, case insensitive"
        ("add":_) -> do
            putStrLn "Add new item. Only item name is required."
            putStrLn "Optional arguments:"
            putStrLn " --description    Item description"
            putStrLn " --dt             Date in the form yyyy-mm-dd, used for sorting siblings in the tree"
            putStrLn " --parent         Parent id. Without this, the new item becomes a top level item"
            putStrLn "Example usage: htree --add \"Item name\" --description \"Item description\" --dt \"2026-01-15\" --parent 3"
        (_:_) ->
            putStrLn "Unrecognized arguments, try 'htree --help' for more information"

listRoots :: Connection -> IO ()
listRoots conn = do
    let sql = "select id, name from item where parent_id is null order by id desc"
    rows <- query_ conn sql :: IO [(Int, T.Text)]

    case rows of
        [] -> putStrLn "No data."
        (_:_) ->
            forM_ rows $ \(itemId, name) ->
                putStrLn $ (T.unpack name) ++ " [" ++ (show itemId) ++ "]"

searchItem :: Connection -> String -> IO ()
searchItem conn name = do
    sqlSearch <- readFileUtf8 "sql/searchByName.sql"
    rows <- query conn (Query sqlSearch) [name] :: IO [Only T.Text]

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
    rowId <- lastInsertRowId conn
    putStrLn $ Fmt.format "Added item: {} [{}]" name (show rowId)

deleteItem :: Connection -> Int -> IO ()
deleteItem conn itemId = do
    let sql = "delete from item where id = ?"
    execute conn sql [itemId]
    putStrLn $ Fmt.format "Deleted item: {}" itemId

moveItem :: Connection -> Int -> Int -> IO ()
moveItem conn itemId parentId = do
    let sql = "update item set parent_id = ? where id = ?"
    execute conn sql (parentId, itemId)
    putStrLn $ Fmt.format "Moved item."

getArg :: String -> [String] -> Maybe String
getArg _ [] = Nothing
getArg _ [_] = Nothing
getArg arg (k:v:xs) | arg == k = Just v | otherwise = getArg arg xs

getConnection :: IO Connection
getConnection = do
    dbFile <- getEnv "DB_FILE"
    conn <- open dbFile
    
    -- enable foreign key enforcement on each connection
    execute_ conn "pragma foreign_keys = on"
    pure conn

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
