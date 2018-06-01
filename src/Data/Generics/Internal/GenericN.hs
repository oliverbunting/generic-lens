{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE InstanceSigs         #-}
{-# LANGUAGE PolyKinds            #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE TypeOperators        #-}
{-# LANGUAGE UndecidableInstances #-}

--------------------------------------------------------------------------------
-- |
-- Module      : Data.Generics.Internal.GenericN
-- Copyright   : (C) 2018 Csongor Kiss
-- Maintainer  : Csongor Kiss <kiss.csongor.kiss@gmail.com>
-- License     : BSD3
-- Stability   : experimental
-- Portability : non-portable
--
-- Generic representation of types with multiple parameters
--
--------------------------------------------------------------------------------

module Data.Generics.Internal.GenericN
  ( Param
  , Rec (Rec, unRec)
  , GenericRepN (..)
  , GenericToN (..)
  , GenericFromN (..)
  ) where

import Data.Kind
import GHC.Generics
import GHC.TypeLits
import Data.Coerce

type family Param :: Nat -> k where

type family Indexed (t :: k) (i :: Nat) :: k where
  Indexed (t a) i = Indexed t (i + 1) (Param i)
  Indexed t _     = t

newtype Rec (p :: Type) a x = Rec { unRec :: K1 R a x }

type family Zip (a :: Type -> Type) (b :: Type -> Type) :: Type -> Type where
  Zip (M1 mt m s) (M1 mt m t)
    = M1 mt m (Zip s t)
  Zip (l :+: r) (l' :+: r')
    = Zip l l' :+: Zip r r'
  Zip (l :*: r) (l' :*: r')
    = Zip l l' :*: Zip r r'
  Zip (Rec0 p) (Rec0 a)
    = Rec p a
  Zip U1 U1
    = U1

class
  ( Coercible (Rep a) (RepN a)
  , Generic a
  ) => GenericRepN (a :: Type) where
  type family RepN (a :: Type) :: Type -> Type

class
  ( Coercible (Rep a) (RepN a)
  , Generic a
  , GenericRepN (a :: Type)
  ) => GenericFromN (a :: Type) where
    fromN :: a -> RepN a x

class
  ( Coercible (Rep a) (RepN a)
  , Generic a
  , GenericRepN (a :: Type)
  ) => GenericToN (a :: Type) where
  toN :: RepN a x -> a

instance
  ( Coercible (Rep a) (RepN a)
  , Generic a
  ) => GenericRepN a where
  type instance RepN a = Zip (Rep (Indexed a 0)) (Rep a)

instance
  ( Coercible (Rep a) (RepN a)
  , Generic a
  , GenericRepN a
  ) => GenericToN a where
  toN :: forall x. RepN a x -> a
  toN   = coerce (to :: Rep a x -> a)
  {-# INLINE toN #-}

instance
  ( Coercible (Rep a) (RepN a)
  , Generic a
  , GenericRepN a
  ) => GenericToN a where
  fromN :: forall x. a -> RepN a x
  fromN = coerce (from :: a -> Rep a x)
  {-# INLINE fromN #-}
