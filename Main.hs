{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Codec.Xlsx
-- import Control.Lens
import qualified Data.ByteString.Lazy as L
-- import qualified Data.Map as M
import System.Environment (getArgs)
import System.FilePath.Posix ((</>))
import System.Directory
import System.IO (stderr, hPutStrLn, hFlush, stdout)
import System.Exit
import Data.List.Extra (trim)

import YBIO
import Applicant

main :: IO ()
main = do
  args <- getArgs
  homeDir <- getHomeDirectory
  let excelFileA :: IO FilePath = case args of
        (x:_) -> return x
        _     -> do
          putStrLn ""
          putStrLn ""
          putStrLn "           ---- YB Application downloader ----"
          putStrLn ""
          putStrLn "* Note: you can hit Control-C at any time to stop or exit this program."
          putStrLn ""
          putStrLn ""
          putStrLn "Please drag an excel (.xlsx) file to process onto the"
          putStrLn "terminal screen and press RETURN"
          putStrLn ""
          putStr "> "
          hFlush stdout
          l <- getLine
          return (trim l)

      outDirA :: IO FilePath = case args of
        (_:y:_) -> return y
        _       -> do
          let defaultDir = homeDir </> "Desktop/ybapp_downloads"
          putStrLn ""
          putStrLn "Please drag a folder to download files into onto the"
          putStrLn "terminal screen and press RETURN"
          putStrLn   $ "[Or just hit RETURN to use: " ++ defaultDir ++ "]: "
          putStrLn ""
          putStr "> "
          hFlush stdout
          l <- getLine
          case l of
            [] -> return defaultDir
            x  -> return (trim x)

  excelFile <- excelFileA
  excelFileExists <- doesFileExist excelFile
  outDir <- outDirA
  outDirExists <- doesDirectoryExist outDir
  case outDirExists of
    True  -> return ()
    False -> ybCreateDirectory outDir
  case excelFileExists of
    False -> do
      hPutStrLn stderr $ "File does not exist: " ++ excelFile
      hFlush stderr
      exitFailure
    True -> do
      bs <- L.readFile excelFile
      runyb outDir $ toXlsx bs

runyb :: FilePath -> Xlsx -> IO ()
runyb topdir xlsx = do
  let applicantSheets = processXlsx xlsx
  mapM_ (downloadSheet topdir) applicantSheets
