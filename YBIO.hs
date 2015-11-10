module YBIO where

import Data.Monoid
import System.Directory
import System.Process
import System.IO
import System.FilePath
import qualified Data.Text.Encoding as TE
import qualified Data.Text as T
import Snap.Core (urlDecode)

ybCreateDirectory :: FilePath -> IO ()
ybCreateDirectory dir = do
  putStrLn $ "Creating directory: " ++ dir
  createDirectory dir

ybDownload :: FilePath -> -- Directory to download into
              String ->   -- Prefix for the downloaded file name
              String ->   -- URL
              IO ()
ybDownload cd prefix url = do
  let fileName = decodeYBUrl url
  case fileName of
    Just fn -> do
      let ffn = cd </> prefix <> (takeFileName fn)
          args = ["-sS", url, "-o", ffn]
          cmd = "curl"
      putStrLn $ "Downloading " ++ fn
      callProcess cmd args
    Nothing -> do
      hPutStrLn stderr $ "Couldn't decode this URL: " ++ url

decodeYBUrl :: String -> Maybe String
decodeYBUrl s = do
  let asT = T.pack s
      asB = TE.encodeUtf8 asT
  bd <- urlDecode asB
  return $ T.unpack $ TE.decodeUtf8 $ bd


