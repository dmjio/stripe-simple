{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RebindableSyntax #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE RankNTypes #-}
module Test.Prelude
       ( ($)
       , Char
       , Functor
       , IO
       , String
       , error
       , module GHC.Num
       , id
       , length
       , undefined
       , return
       , (>>=)
       , (>>)
       , fail
       , void
       , liftIO
       , fromString
       , stripeLift
       , module Test.Hspec
       , Eq(..)
       , Bool(..)
       , Maybe(..)
       , Stripe
       , StripeF(..)
       , StripeSpec
       ) where

import           Data.Aeson
import           Data.ByteString (ByteString)
import           Data.Either     (Either)
import           Data.String     (fromString)
import           Data.Maybe      (Maybe(..))
import           GHC.Num         (fromInteger)
import           Prelude         (Bool(..), Eq(..), Functor, ($), IO, Char, String, error, undefined, id, length)
import           Test.Hspec
import           Test.Hspec.Core (SpecM)
import qualified Control.Monad   as M
import qualified Control.Monad.Trans as M
import           Control.Monad.Trans.Free (FreeT(..), liftF)
import           Web.Stripe

------------------------------------------------------------------------------
-- hack Monad functions to automatically insert callAPI around StripeRequests

data StripeF a = StripeF (ByteString -> Either String a) (StripeRequest a) deriving Functor
type Stripe = FreeT StripeF IO

type StripeSpec = (forall a. Stripe a -> IO (Either StripeError a)) -> Spec

callAPI :: (FromJSON a) => StripeRequest a -> Stripe a
callAPI req = liftF (StripeF eitherDecodeStrict' req)

void :: (FromJSON a) => StripeRequest a -> Stripe ()
void req = M.void (callAPI req)

class StripeLift a where
  type LiftedType a
  stripeLift :: a -> (LiftedType a)

(>>=) :: (StripeLift t, M.Monad m, LiftedType t ~ m a) =>
         t -> (a -> m b) -> m b
m >>= f = (stripeLift m) M.>>= f

(>>) :: (StripeLift t, M.Monad m, LiftedType t ~ m a) => t -> m b -> m b
(>>) m n = m >>= \_ -> n

fail :: (M.Monad m) => String -> m a
fail = M.fail

return :: (M.Monad m) => a -> m a
return = M.return

liftIO :: IO a -> Stripe a
liftIO io = M.liftIO io

instance (FromJSON a) => StripeLift (StripeRequest a) where
  type LiftedType (StripeRequest a) = Stripe a
  stripeLift req = callAPI req

instance (FromJSON a) => StripeLift (Stripe a) where
  type LiftedType (Stripe a) = Stripe a
  stripeLift = id

instance StripeLift (IO a) where
  type LiftedType (IO a) = IO a
  stripeLift = id

instance StripeLift (SpecM a) where
  type LiftedType (SpecM a) = SpecM a
  stripeLift = id
