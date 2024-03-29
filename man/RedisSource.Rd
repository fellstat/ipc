% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/redis-source.R
\name{RedisSource}
\alias{RedisSource}
\title{Reads and writes the queue to a redis db}
\description{
Reads and writes the queue to a redis db

Reads and writes the queue to a redis db
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-RedisSource-new}{\code{RedisSource$new()}}
\item \href{#method-RedisSource-getRedisConnection}{\code{RedisSource$getRedisConnection()}}
\item \href{#method-RedisSource-pop}{\code{RedisSource$pop()}}
\item \href{#method-RedisSource-push}{\code{RedisSource$push()}}
\item \href{#method-RedisSource-destroy}{\code{RedisSource$destroy()}}
\item \href{#method-RedisSource-finalize}{\code{RedisSource$finalize()}}
\item \href{#method-RedisSource-clone}{\code{RedisSource$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-new"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-new}{}}}
\subsection{Method \code{new()}}{
Creates a redis source object.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$new(id = redisIdGenerator()(), config = redisConfig())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{id}}{An identifier to use for the queue}

\item{\code{config}}{A configuration list for redux::hiredis}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-getRedisConnection"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-getRedisConnection}{}}}
\subsection{Method \code{getRedisConnection()}}{
Returns the underlying redis connection.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$getRedisConnection()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-pop"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-pop}{}}}
\subsection{Method \code{pop()}}{
removes n items from the source and returns them
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$pop(n = -1)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{n}}{The number of records to pop (-1 indicates all available).}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-push"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-push}{}}}
\subsection{Method \code{push()}}{
Adds an item to the source.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$push(msg, obj)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{msg}}{A string indicating the signal.}

\item{\code{obj}}{The object to associate with the signal.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-destroy"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-destroy}{}}}
\subsection{Method \code{destroy()}}{
Cleans up source after use.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$destroy()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-finalize"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-finalize}{}}}
\subsection{Method \code{finalize()}}{
finalize
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$finalize()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-RedisSource-clone"></a>}}
\if{latex}{\out{\hypertarget{method-RedisSource-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{RedisSource$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
