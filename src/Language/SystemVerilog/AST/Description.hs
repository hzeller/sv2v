{- sv2v
 - Author: Zachary Snow <zach@zachjs.com>
 - Initial Verilog AST Author: Tom Hawkins <tomahawkins@gmail.com>
 -
 - SystemVerilog top-level items (descriptions, package items)
 -}

module Language.SystemVerilog.AST.Description
    ( Description (..)
    , PackageItem (..)
    , PartKW      (..)
    , Lifetime    (..)
    ) where

import Data.Maybe (fromMaybe)
import Data.List (intercalate)
import Text.Printf (printf)

import Language.SystemVerilog.AST.ShowHelp

import Language.SystemVerilog.AST.Attr (Attr)
import Language.SystemVerilog.AST.Decl (Decl)
import Language.SystemVerilog.AST.Stmt (Stmt)
import Language.SystemVerilog.AST.Type (Type, Identifier)
import {-# SOURCE #-} Language.SystemVerilog.AST.ModuleItem (ModuleItem)

data Description
    = Part [Attr] Bool PartKW (Maybe Lifetime) Identifier [Identifier] [ModuleItem]
    | PackageItem PackageItem
    | Package (Maybe Lifetime) Identifier [PackageItem]
    | Directive String -- currently unused
    deriving Eq

instance Show Description where
    showList descriptions _ = intercalate "\n" $ map show descriptions
    show (Part attrs True  kw lifetime name _ items) =
        printf "%sextern %s %s%s %s;"
            (concatMap showPad attrs)
            (show kw) (showLifetime lifetime) name (indentedParenList itemStrs)
        where itemStrs = map (init . show) items
    show (Part attrs False kw lifetime name ports items) =
        printf "%s%s %s%s%s;\n%s\nend%s"
            (concatMap showPad attrs)
            (show kw) (showLifetime lifetime) name portsStr bodyStr (show kw)
        where
            portsStr = if null ports
                then ""
                else " " ++ indentedParenList ports
            bodyStr = indent $ unlines' $ map show items
    show (Package lifetime name items) =
        printf "package %s%s;\n%s\nendpackage"
            (showLifetime lifetime) name bodyStr
        where
            bodyStr = indent $ unlines' $ map show items
    show (PackageItem i) = show i
    show (Directive str) = str

data PackageItem
    = Typedef Type Identifier
    | Function (Maybe Lifetime) Type Identifier [Decl] [Stmt]
    | Task     (Maybe Lifetime)      Identifier [Decl] [Stmt]
    | Import Identifier (Maybe Identifier)
    | Export (Maybe (Identifier, Maybe Identifier))
    | Decl Decl
    | Comment String
    deriving Eq

instance Show PackageItem where
    show (Typedef t x) = printf "typedef %s %s;" (show t) x
    show (Function ml t x i b) =
        printf "function %s%s%s;\n%s\n%s\nendfunction"
            (showLifetime ml) (showPad t) x (indent $ show i)
            (indent $ unlines' $ map show b)
    show (Task ml x i b) =
        printf "task %s%s;\n%s\n%s\nendtask"
            (showLifetime ml) x (indent $ show i)
            (indent $ unlines' $ map show b)
    show (Import x y) = printf "import %s::%s;" x (fromMaybe "*" y)
    show (Export Nothing) = "export *::*";
    show (Export (Just (x, y))) = printf "export %s::%s;" x (fromMaybe "*" y)
    show (Decl decl) = show decl
    show (Comment c) =
        if elem '\n' c
            then "// " ++ show c
            else "// " ++ c

data PartKW
    = Module
    | Interface
    deriving Eq

instance Show PartKW where
    show Module    = "module"
    show Interface = "interface"

data Lifetime
    = Static
    | Automatic
    deriving (Eq, Ord)

instance Show Lifetime where
    show Static    = "static"
    show Automatic = "automatic"

showLifetime :: Maybe Lifetime -> String
showLifetime Nothing = ""
showLifetime (Just l) = show l ++ " "
