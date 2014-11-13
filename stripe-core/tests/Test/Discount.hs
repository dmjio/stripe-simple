{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RebindableSyntax #-}
module Test.Discount where

import           Data.Either
import           Test.Hspec
import           Test.Util
import           Test.Prelude

import           Web.Stripe.Coupon
import           Web.Stripe.Customer
import           Web.Stripe.Discount
import           Web.Stripe.Plan
import           Web.Stripe.Subscription

discountTests :: StripeSpec
discountTests stripe = do
  describe "Discount tests" $ do
    it "Succesfully deletes a discount from a Customer" $ do
      coupon <- makeCouponId
      result <- stripe $ do
        Coupon { couponId = couponid } <-
          createCoupon
             (Just coupon)
             Once
             (Just $ AmountOff 1)
             (Just USD)
             Nothing
             Nothing
             Nothing
             Nothing
             []
        Customer { customerId = customerid } <-
          createCustomerBase
            Nothing
            Nothing
            Nothing
            Nothing
            Nothing
            Nothing
            (Just coupon)
            Nothing
            Nothing
            Nothing
            Nothing
            Nothing
            []
        r <- deleteCustomerDiscount customerid
        c <- getCustomer customerid
        void $ deleteCustomer customerid
        void $ deleteCoupon couponid
        return (r,c)
      result `shouldSatisfy` isRight
      let Right (_, Customer{..}) = result
      customerDiscount `shouldBe` Nothing
    it "Succesfully deletes a discount from a Subscription" $ do
      coupon <- makeCouponId
      plan <- makePlanId
      result <- stripe $ do
        Plan { planId = planid } <-
          createPlan plan
          0 -- free plan
          USD
          Month
          "sample plan"
          []
        Coupon { couponId = couponid } <-
          createCoupon
             (Just coupon)
             Once
             (Just $ AmountOff 1)
             (Just USD)
             Nothing
             Nothing
             Nothing
             Nothing
             []
        Customer { customerId = customerid } <-
          createCustomerBase
            Nothing
            Nothing
            Nothing
            Nothing
            Nothing
            Nothing
            (Just coupon)
            Nothing
            Nothing
            Nothing
            Nothing
            Nothing
            []
        Subscription { subscriptionId = sid } <-
          createSubscription customerid plan []
        void $ updateSubscription customerid sid (Just coupon) []
        result <- deleteSubscriptionDiscount customerid sid
        void $ deletePlan planid
        void $ deleteCustomer customerid
        void $ deleteCoupon couponid
        return result
      result `shouldSatisfy` isRight




