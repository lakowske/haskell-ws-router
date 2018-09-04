--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Main
    ( main
    ) where


--------------------------------------------------------------------------------
import           Control.Concurrent  (forkIO)
import           Control.Monad       (forever, unless)
import           Control.Monad.Trans (liftIO)
import           Network.Socket      (withSocketsDo)
import           Data.Text           (Text)
import System.Process
import qualified Data.Text           as T
import qualified Data.Text.IO        as T
import qualified Network.WebSockets  as WS
import System.Environment
import qualified System.Exit         as E
import qualified Server              as S

--------------------------------------------------------------------------------
app :: WS.ClientApp ()
app conn = do
    putStrLn "Connected!"

    -- Fork a thread that writes WS data to stdout
    _ <- forkIO $ forever $ do
        msg <- WS.receiveData conn
        processMsg msg

    -- Read from stdin and write to WS
    let loop = do
            line <- T.getLine
            unless (T.null line) $ WS.sendTextData conn line >> loop

    loop
    WS.sendClose conn ("Bye!" :: Text)

processMsg :: T.Text -> IO ()
processMsg msg = do
  r <- createProcess (proc "bash" [ "-c", T.unpack msg ])
  liftIO $ T.putStrLn msg


--------------------------------------------------------------------------------
mainConnect :: String -> IO ()
mainConnect host = withSocketsDo $ WS.runClient host 3000 "/" app

usage   = putStrLn "Usage: haskell-client [-vhd] host"
version = putStrLn "Haskell client 0.1"
exit    = E.exitWith E.ExitSuccess
die     = E.exitWith (E.ExitFailure 1)

parse :: [String] -> IO ()
parse ["-h"] = usage   >> exit
parse ["-v"] = version >> exit
parse ["-d"] = S.run >> exit
parse []     = usage >> die
parse [host]   = mainConnect host >> exit

main :: IO ()
main = getArgs >>= parse >> (putStr "all done")
