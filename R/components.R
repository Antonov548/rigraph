#   IGraph R package
#   Copyright (C) 2005-2012  Gabor Csardi <csardi.gabor@gmail.com>
#   334 Harvard street, Cambridge, MA 02139 USA
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc.,  51 Franklin Street, Fifth Floor, Boston, MA
#   02110-1301 USA
#
###################################################################

###################################################################
# Connected components, subgraphs, kinda
###################################################################

#' @family components
#' @export
count_components <- function(graph, mode = c("weak", "strong")) {
  ensure_igraph(graph)
  mode <- igraph.match.arg(mode)
  mode <- switch(mode,
    "weak" = 1,
    "strong" = 2
  )

  on.exit(.Call(R_igraph_finalizer))
  .Call(R_igraph_no_clusters, graph, as.numeric(mode))
}

#' @rdname components
#' @param cumulative Logical, if TRUE the cumulative distirubution (relative
#'   frequency) is calculated.
#' @param mul.size Logical. If TRUE the relative frequencies will be multiplied
#'   by the cluster sizes.
#' @family components
#' @export
#' @importFrom graphics hist
component_distribution <- function(graph, cumulative = FALSE, mul.size = FALSE,
                                   ...) {
  ensure_igraph(graph)

  cs <- components(graph, ...)$csize
  hi <- hist(cs, -1:max(cs), plot = FALSE)$density
  if (mul.size) {
    hi <- hi * 1:max(cs)
    hi <- hi / sum(hi)
  }
  if (!cumulative) {
    res <- hi
  } else {
    res <- rev(cumsum(rev(hi)))
  }

  res
}



#' Decompose a graph into components
#'
#' Creates a separate graph for each connected component of a graph.
#'
#' @aliases decompose.graph
#' @param graph The original graph.
#' @param mode Character constant giving the type of the components, wither
#'   `weak` for weakly connected components or `strong` for strongly
#'   connected components.
#' @param max.comps The maximum number of components to return. The first
#'   `max.comps` components will be returned (which hold at least
#'   `min.vertices` vertices, see the next parameter), the others will be
#'   ignored. Supply `NA` here if you don't want to limit the number of
#'   components.
#' @param min.vertices The minimum number of vertices a component should
#'   contain in order to place it in the result list. E.g. supply 2 here to ignore
#'   isolate vertices.
#' @return A list of graph objects.
#' @author Gabor Csardi \email{csardi.gabor@@gmail.com}
#' @seealso [is_connected()] to decide whether a graph is connected,
#' [components()] to calculate the connected components of a graph.
#' @family components
#' @export
#' @keywords graphs
#' @examples
#'
#' # the diameter of each component in a random graph
#' g <- sample_gnp(1000, 1 / 1000)
#' components <- decompose(g, min.vertices = 2)
#' sapply(components, diameter)
#'
decompose <- function(graph, mode = c("weak", "strong"), max.comps = NA,
                      min.vertices = 0) {
  ensure_igraph(graph)
  mode <- igraph.match.arg(mode)
  mode <- switch(mode,
    "weak" = 1,
    "strong" = 2
  )

  if (is.na(max.comps)) {
    max.comps <- -1
  }
  on.exit(.Call(R_igraph_finalizer))
  .Call(
    R_igraph_decompose, graph, as.numeric(mode),
    as.numeric(max.comps), as.numeric(min.vertices)
  )
}


#' Articulation points and bridges of a graph
#'
#' `articulation_points()` finds the articulation points (or cut vertices)
# " of a graph, while \code{bridges()} finds the bridges (or cut-edges) of a graph.
#'
#' Articulation points or cut vertices are vertices whose removal increases the
#' number of connected components in a graph. Similarly, bridges or cut-edges
#' are edges whose removal increases the number of connected components in a
#' graph. If the original graph was connected, then the removal of a single
#' articulation point or a single bridge makes it undirected. If a graph
#' contains no articulation points, then its vertex connectivity is at least
# " two. If a graph contains no bridges, then its edge connectivity is at least
#' two.
#'
#' @aliases articulation.points articulation_points
#' @param graph The input graph. It is treated as an undirected graph, even if
#'   it is directed.
#' @return For `articulation_points()`, a numeric vector giving the vertex
#'   IDs of the articulation points of the input graph. For `bridges()`, a
#'   numeric vector giving the edge IDs of the bridges of the input graph.
#' @author Gabor Csardi \email{csardi.gabor@@gmail.com}
#' @seealso [biconnected_components()], [components()],
#' [is_connected()], [vertex_connectivity()],
#' [edge_connectivity()]
#' @keywords graphs
#' @examples
#'
#' g <- disjoint_union(make_full_graph(5), make_full_graph(5))
#' clu <- components(g)$membership
#' g <- add_edges(g, c(match(1, clu), match(2, clu)))
#' articulation_points(g)
#'
#' g <- make_graph("krackhardt_kite")
#' bridges(g)
#'
#' @family components
#' @export
articulation_points <- articulation_points_impl

#' @rdname articulation_points
#' @family components
#' @export
bridges <- bridges_impl


#' Biconnected components
#'
#' Finding the biconnected components of a graph
#'
#' A graph is biconnected if the removal of any single vertex (and its adjacent
#' edges) does not disconnect it.
#'
#' A biconnected component of a graph is a maximal biconnected subgraph of it.
#' The biconnected components of a graph can be given by the partition of its
#' edges: every edge is a member of exactly one biconnected component. Note
#' that this is not true for vertices: the same vertex can be part of many
#' biconnected components.
#'
#' @aliases biconnected.components biconnected_components
#' @param graph The input graph. It is treated as an undirected graph, even if
#'   it is directed.
#' @return A named list with three components: \item{no}{Numeric scalar, an
#'   integer giving the number of biconnected components in the graph.}
#'   \item{tree_edges}{The components themselves, a list of numeric vectors. Each
#'   vector is a set of edge ids giving the edges in a biconnected component.
#'   These edges define a spanning tree of the component.}
#'   \item{component_edges}{A list of numeric vectors. It gives all edges in the
#'   components.} \item{components}{A list of numeric vectors, the vertices of
#'   the components.} \item{articulation_points}{The articulation points of the
#'   graph. See [articulation_points()].}
#' @author Gabor Csardi \email{csardi.gabor@@gmail.com}
#' @seealso [articulation_points()], [components()],
#' [is_connected()], [vertex_connectivity()]
#' @keywords graphs
#' @examples
#'
#' g <- disjoint_union(make_full_graph(5), make_full_graph(5))
#' clu <- components(g)$membership
#' g <- add_edges(g, c(which(clu == 1), which(clu == 2)))
#' bc <- biconnected_components(g)
#' @family components
#' @export
biconnected_components <- biconnected_components_impl


#' @rdname components
#' @family components
#' @export
largest_component <- function(graph, mode = c("weak", "strong")) {
  if (!is_igraph(graph)) {
    stop("Not a graph object")
  }
  
  comps <- components(graph, mode = mode)

  lcc_id <- which.max(comps$csize)
  vids <- V(graph)[comps$membership == lcc_id]

  induced_subgraph(graph, vids)
}
