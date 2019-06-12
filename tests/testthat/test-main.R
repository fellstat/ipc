context("Main")
library(testthat)
library(future)
plan(multisession)

skip_if_no_redis <- function(...) {
  testthat::skip_on_cran()
  if (redux::redis_available(...)) {
    return()
  }
  testthat::skip("Redis is not available")
}

mainTests <- function(q){
  # Test push / pop
  q$push("dsds",list())
  expect_identical(q$pop(-1),
                   structure(list(dsds = list()), .Names = "dsds"))
  expect_identical(q$pop(-1), list())

  cons <- ShinyConsumer$new(q)
  prod <- ShinyProducer$new(q)
  # Check interrupt
  prod$fireInterrupt()
  expect_error(cons$consume())


  # Test evaluation
  a <- 3
  prod$fireEval(stop("testerror", call.=FALSE))
  prod$fireEval(a <- 2)
  expect_error(cons$consume())
  expect_true(a == 2)

  b <- 1
  prod$fireEval(b <- 2)
  cons$consume()
  expect_true(b == 2)

  b <- 1
  a <- 4
  prod$fireEval(b <- a, env = list(a=a))
  rm(a)
  cons$consume()
  expect_true(b == 4)


  # Test Functors
  b <- 1
  f <- function(x){
    b <<- abs(x)
  }
  prod$fireDoCall("f", list(x=c(-1,0,1)))
  cons$consume()
  expect_equivalent(b, c(1,0,1))

  # Test Evaluation Context
  b <- 1
  cc <- (function(){
    b <- 5
    cons2 <- ShinyConsumer$new(q)
    prod$fireEval(b <- 2)
    cons2$consume()
    expect_true(b == 2)
    prod$fireEval(b <- 3)
    cons2
  })()
  expect_true(b == 1)
  cc$consume()
  expect_true(b == 3)

  # Test in Future
  prod$fireEval(b <- 2)
  b <- 5
  f <- future({
    b <- 4
    cons$consume()
    c <- b
    prod$fireEval(b <- 1)
    c
  })
  v <- value(f)
  expect_true(v == 2)
  cons$consume()
  expect_true(b == 1)
}

test_that("Main Tests With TextFileSource", {
  q <- TextFileSource$new()

  mainTests(q)

  q$destroy()
})

test_that("Main Tests With RedisSource", {
  skip_if_no_redis()
  q <- RedisSource$new()

  mainTests(q)

  q$destroy()
})

test_that("File Truncation", {
  # Test file truncation
  tq <- ipc:::.TxTQ$new(tempfile())
  tq$mr(7) #maxRows <- 7
  for(i in 1:5){
    tq$push("test",as.character(i))
  }
  file <- tq[['.__enclos_env__']]$private$db_file
  expect_true(length(readLines(file)) == 5)
  tq$pop(-1)
  expect_true(length(readLines(file))  == 5)
  for(i in 1:5){
    tq$push("test",as.character(i))
  }
  tq$pop(-1)
  expect_true(length(readLines(file)) == 0)
})






