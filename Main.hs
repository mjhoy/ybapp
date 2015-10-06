{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Codec.Xlsx
import qualified Data.ByteString.Lazy as L
import qualified Data.Map as M
import Data.Text (Text)
import Control.Lens
import System.Environment (getExecutablePath)
import System.FilePath.Posix (takeDirectory)

main :: IO ()
main = do
  execP <- getExecutablePath
  let execD = takeDirectory execP
  bs <- L.readFile (execD ++ "/test.xlsx")
  -- let value = toXlsx bs ^? ixSheet "sheet1" .
  --             ixCell (3,2) . cellValue . _Just
  let value = getSheetNames $ toXlsx bs
  putStrLn $ (show value)

getSheetNames :: Xlsx -> [Text]
getSheetNames = M.keys . _xlSheets
  
