{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Codec.Xlsx
import Control.Lens
import qualified Data.ByteString.Lazy as L
import qualified Data.Map as M
import Data.Text (Text)
import qualified Data.Text as T
import System.Environment (getExecutablePath,
                           getArgs)
import System.FilePath.Posix (takeDirectory,
                              (</>))
import System.Directory
import System.IO (stderr, hPutStrLn)
import System.Exit
import Control.Monad
import Data.Maybe (mapMaybe)
import Text.Regex.TDFA

import YBIO

data ApplicantSheet = ApplicantSheet {
    _sheetName  :: String
  , _applicants :: [Applicant]
  } deriving (Show)

data Applicant = Applicant {
  _downloadURLs :: [String]
  } deriving (Show)

makeLenses ''Applicant
makeLenses ''ApplicantSheet

-- will match all yellowbarn-looking strings within `text'
matchYBUrl :: Text -> [String]
matchYBUrl text = mapMaybe (\i -> i ^? (ix 0)) result
  where result :: [[String]] = (T.unpack text) =~ ("https?://(www\\.)yellowbarn.org[^\\S]*[a-zA-Z]+" :: String)

main :: IO ()
main = do
  execP <- getExecutablePath
  args <- getArgs
  homeDir <- getHomeDirectory
  let execD = takeDirectory execP
      testFile = case args of
        (x:_) -> x
        _      -> execD </> "test.xlsx"
      outDir = case args of
        (_:y:_) -> y
        _       -> homeDir </> "Desktop/ybapp_downloads"
  testFileExists <- doesFileExist testFile
  outDirExists <- doesDirectoryExist outDir
  case outDirExists of
    True  -> return ()
    False -> ybCreateDirectory outDir
  case testFileExists of
    False -> do
      hPutStrLn stderr $ "File does not exist: " ++ testFile
      exitFailure
    True -> do
      bs <- L.readFile testFile
      processXlsx outDir $ toXlsx bs

processXlsx :: FilePath -> Xlsx -> IO ()
processXlsx topdir xlsx = do
  let sheets = M.assocs $ xlsx ^. xlSheets
      applicantSheets = map (uncurry processSheet) sheets
  mapM_ (downloadSheet topdir) applicantSheets

downloadSheet :: FilePath -> ApplicantSheet -> IO ()
downloadSheet topdir sheet = do
  let dir = topdir </> sheet ^. sheetName
  exists <- doesDirectoryExist dir
  case exists of
    True -> do
      return ()
    False -> do
      ybCreateDirectory dir
  forM_ (sheet ^. applicants) $ \applicant -> do
    mapM_ (ybDownload dir) (applicant ^. downloadURLs)

rowToApplicant :: (Int, [(Int, Cell)]) -> Applicant
rowToApplicant (_ridx, cols) = Applicant $ concat $ map colToUrl cols
  where colToUrl (_, cell) = case (cell ^. cellValue) of
                                   Just (CellText t) -> do
                                     matchYBUrl t
                                   _ -> []

processSheet :: Text ->         -- Sheet name
                Worksheet ->    -- xlsx worksheet
                ApplicantSheet
processSheet name sheet = do
  let cellMap  = sheet ^. wsCells
      cellRows = toRows cellMap
      as       = map rowToApplicant cellRows
  ApplicantSheet (T.unpack name) as
