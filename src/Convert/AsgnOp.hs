{- sv2v
 - Author: Zachary Snow <zach@zachjs.com>
 -
 - Conversion for binary assignment operators, which can appear in for loops and
 - as a special case of blocking assignment statements. We simply elaborate them
 - in the obvious manner: a += b -> a = a + b.
 -}

module Convert.AsgnOp (convert) where

import Convert.Traverse
import Language.SystemVerilog.AST

convert :: [AST] -> [AST]
convert =
    map $ traverseDescriptions $ traverseModuleItems $
    ( traverseStmts    convertStmt
    . traverseGenItems convertGenItem
    )

convertGenItem :: GenItem -> GenItem
convertGenItem (GenFor a b (ident, AsgnOp op, expr) c d) =
    GenFor a b (ident, AsgnOpEq, BinOp op (Ident ident) expr) c d
convertGenItem other = other

convertStmt :: Stmt -> Stmt
convertStmt (For inits cc asgns stmt) =
    For inits cc asgns' stmt
    where
        asgns' = map convertAsgn asgns
        convertAsgn :: (LHS, AsgnOp, Expr) -> (LHS, AsgnOp, Expr)
        convertAsgn (lhs, AsgnOp op, expr) =
            (lhs, AsgnOpEq, BinOp op (lhsToExpr lhs) expr)
        convertAsgn other = other
convertStmt (AsgnBlk (AsgnOp op) lhs expr) =
    AsgnBlk AsgnOpEq lhs (BinOp op (lhsToExpr lhs) expr)
convertStmt other = other
