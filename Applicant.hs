{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Applicant ( ApplicantSheet
                 , sheetName
                 , applicants
                 , Applicant
                 , downloadURLs
                 , name
                 , rowToApplicant
                 , processSheet
                 , processXlsx
                 , downloadSheet
                 ) where

import Data.Monoid
import Codec.Xlsx
import Control.Lens
import qualified Data.Text as T
import qualified Data.Map as M
import Text.Regex.TDFA
import Data.Maybe
import Data.Text (Text)
import System.Directory
import System.FilePath
import Control.Monad

import YBIO

data ApplicantSheet = ApplicantSheet {
    _sheetName  :: String
  , _applicants :: [Applicant]
  } deriving (Show)

data Applicant = Applicant {
  _name :: Maybe String,
  _downloadURLs :: [String]
  } deriving (Show)

makeLenses ''Applicant
makeLenses ''ApplicantSheet

-- will match all yellowbarn-looking strings within `text'
matchYBUrl :: Text -> [String]
matchYBUrl text = mapMaybe (\i -> i ^? (ix 0)) result
  where result :: [[String]] = (T.unpack text) =~ ("https?://(www\\.)yellowbarn.org[^\\S]*[a-zA-Z]+" :: String)

rowToApplicant :: (Int, [(Int, Cell)]) -> Applicant
rowToApplicant (_ridx, cols) = Applicant name $ concat $ map colToUrl cols
  where colToUrl (_, cell) = case (cell ^. cellValue) of
                                   Just (CellText t) -> do
                                     matchYBUrl t
                                   _ -> []
        name = do
          cell <- cols ^? ix 0
          case cell ^. _2 ^. cellValue of
            Just (CellText t) -> return $ T.unpack t
            _ -> Nothing



processXlsx :: Xlsx -> [ApplicantSheet]
processXlsx xlsx = map (uncurry processSheet) sheets
  where sheets = M.assocs $ xlsx ^. xlSheets

-- Take an XLSX worksheet and produce an Applicant Sheet.
processSheet :: Text ->         -- Sheet name
                Worksheet ->    -- xlsx worksheet
                ApplicantSheet
processSheet name sheet = do
  let cellMap  = sheet ^. wsCells
      cellRows = toRows cellMap
      as       = map rowToApplicant cellRows
  ApplicantSheet (T.unpack name) as

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
      let name' = fromMaybe "Unknown name" (applicant ^. name)
      mapM_ (ybDownload dir (name' <> " -- ")) (applicant ^. downloadURLs)
