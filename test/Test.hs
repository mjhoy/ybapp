{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Test.Hspec
import qualified Data.ByteString.Lazy as L
import Codec.Xlsx (toXlsx)
import Control.Lens
import Applicant

main :: IO ()
main = hspec $ do
  describe "processSheet" $ do

    let testExcelFile = "test/xlsx-test.xlsx"
        (sheetsA :: IO [ApplicantSheet]) = do
          bs <- L.readFile testExcelFile
          return $ processXlsx (toXlsx bs)

    it "loads both sheets" $ do
      sheets <- sheetsA
      length sheets `shouldBe` 2

    it "takes the header row" $ do
      sheets <- sheetsA
      let (headersURLs :: Maybe [String]) = do
            firstSheet <- sheets ^? ix 0
            headers <- firstSheet ^. applicants ^? ix 0
            return $ headers ^. downloadURLs
      headersURLs `shouldBe` Just []

    it "gets monteverdi" $ do
      sheets <- sheetsA
      let monteverdiURL :: Maybe String = do
            sheet <- sheets ^? ix 1 -- note: sheets appear to be alphabeticized
            monteverdi <- sheet ^. applicants ^? ix 1
            monteverdi ^. downloadURLs ^? ix 0
      monteverdiURL `shouldBe` Just "http://www.yellowbarn.org/mv1.doc"
