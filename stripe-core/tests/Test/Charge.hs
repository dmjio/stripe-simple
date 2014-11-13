{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE RebindableSyntax #-}
module Test.Charge where

import           Data.Either
import           Data.Text              (Text)
import           Test.Hspec
import           Test.Prelude
import           Web.Stripe.Charge
import           Web.Stripe.Customer

chargeTests :: StripeSpec
chargeTests stripe =
  describe "Charge tests" $ do
    chargeCustomerTest
    retrieveChargeTest
    updateChargeTest
    retrieveExpandedChargeTest
    retrieveAllChargesTest
    captureChargeTest
  where
    cn  = CardNumber "4242424242424242"
    em  = ExpMonth 12
    ey  = ExpYear 2015
    cvc = CVC "123"
    chargeCustomerTest =
      it "Charges a customer succesfully" $ do
        result <- stripe $ do
          Customer { customerId = cid } <- createCustomerByCard cn em ey cvc
          charge <- chargeCustomer cid USD 100 Nothing
          void $ deleteCustomer cid
          return charge
        result `shouldSatisfy` isRight
    retrieveChargeTest =
      it "Retrieves a charge succesfully" $ do
        result <- stripe $ do
          Customer { customerId = cid } <- createCustomerByCard cn em ey cvc
          Charge { chargeId = chid } <- chargeCustomer cid USD 100 Nothing
          result <- getCharge chid
          void $ deleteCustomer cid
          return result
        result `shouldSatisfy` isRight
    updateChargeTest =
      it "Updates a charge succesfully" $ do
        result <- stripe $ do
          Customer { customerId = cid } <- createCustomerByCard cn em ey cvc
          Charge { chargeId = chid } <- chargeCustomer cid USD 100 Nothing
          _ <- updateCharge chid "Cool" [("hi", "there")]
          result <- getCharge chid
          void $ deleteCustomer cid
          return result
        result `shouldSatisfy` isRight
        let Right Charge { chargeMetaData = cmd, chargeDescription = desc } = result
        cmd `shouldBe` [("hi", "there")]
        desc `shouldSatisfy` (==(Just "Cool" :: Maybe Text))
    retrieveExpandedChargeTest =
      it "Retrieves an expanded charge succesfully" $ do
        result <- stripe $ do
          Customer { customerId = cid } <- createCustomerByCard cn em ey cvc
          Charge { chargeId = chid } <- chargeCustomer cid USD 100 Nothing
          result <- getChargeExpandable chid ["balance_transaction", "customer", "invoice"]
          void $ deleteCustomer cid
          return result
        result `shouldSatisfy` isRight
    retrieveAllChargesTest =
      it "Retrieves all charges" $ do
        result <- stripe $ do c <- getCharges Nothing Nothing Nothing
                              return c
        result `shouldSatisfy` isRight
    captureChargeTest =
      it "Captures a charge - 2 Step Payment Flow" $ do
        result <- stripe $ do
          Customer { customerId = cid } <- createCustomerByCard cn em ey cvc
          Charge { chargeId = chid } <- chargeBase 100 USD Nothing (Just cid)
                                        Nothing Nothing Nothing False
                                        Nothing Nothing Nothing Nothing []
          result <- captureCharge chid Nothing Nothing
          void $ deleteCustomer cid
          return result
        result `shouldSatisfy` isRight
        let Right Charge { chargeCaptured = captured } = result
        captured `shouldBe` True
