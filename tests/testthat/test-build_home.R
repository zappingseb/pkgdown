context("build_home")


# license -----------------------------------------------------------------

test_that("link_license matchs exactly", {
  # Shouldn't match first GPL-2
  expect_equal(
    autolink_license("LGPL-2") ,
    "<a href='https://www.r-project.org/Licenses/LGPL-2'>LGPL-2</a>"
  )
})

test_that("link_license matches LICENSE", {
  expect_equal(
    autolink_license("LICENSE") ,
    "<a href='LICENSE.html'>LICENSE</a>"
  )
})


# index -------------------------------------------------------------------

test_that("intermediate files cleaned up automatically", {
  pkg <- test_path("home-index-rmd")
  expect_output(build_home(pkg, tempdir()))

  expect_equal(dir(pkg), c("DESCRIPTION", "index.Rmd"))
})

test_that("intermediate files cleaned up automatically", {
  pkg <- test_path("home-readme-rmd")
  expect_output(build_home(pkg, tempdir()))

  expect_equal(sort(dir(pkg)), sort(c("DESCRIPTION", "README.md", "README.Rmd")))
})


# tweaks ------------------------------------------------------------------

test_that("page header modification succeeds", {
  html <- xml2::read_html('
    <h1 class="hasAnchor">
      <a href="#plot" class="anchor"> </a>
      <img src="someimage" alt=""> some text
    </h1>')

  tweak_homepage_html(html)

  expect_output_file(cat(as.character(html)), "home-page-header.html")
})

test_that("links to vignettes & figures tweaked", {
  html <- xml2::read_html('
    <img src="vignettes/x.png" />
    <img src="man/figures/x.png" />
  ')

  tweak_homepage_html(html)

  expect_output_file(cat(as.character(html)), "home-links.html")
})


# cran or bioc ------------------------------------------------------------


test_that("package repo verification", {
  bioc_ver <- if (requireNamespace("BiocInstaller", quietly = TRUE)) {
    BiocInstaller::biocVersion()
    } else { "release" }
  expect_identical(names(repo_url("dplyr")), "CRAN")
  expect_identical(names(repo_url("Biobase")), "BIOC")

  expect_null(repo_url("notarealpkg"))

  expect_identical(repo_url("dplyr", cran = "https://cloud.r-project.org"),
    c(CRAN = "https://cloud.r-project.org/web/packages/dplyr/index.html"))
  expect_identical(repo_url("Biobase"),
    c(BIOC = paste0("https://bioconductor.org/packages/", bioc_ver,
                    "/bioc/html/Biobase.html")))

})


# links and references in the package description -------------------------

test_that("references in angle brackets are converted to HTML", {
  ## URL
  expect_identical(
    linkify("see <https://CRAN.R-project.org/view=SpatioTemporal>."),
    "see &lt;<a href='https://CRAN.R-project.org/view=SpatioTemporal'>https://CRAN.R-project.org/view=SpatioTemporal</a>&gt;."
  )
  ## DOI
  expect_identical(
    linkify("M & H (2017) <doi:10.1093/biostatistics/kxw051>"),
    "M &amp; H (2017) &lt;<a href='https://doi.org/10.1093/biostatistics/kxw051'>doi:10.1093/biostatistics/kxw051</a>&gt;"
  )
  ## arXiv
  expect_identical(
    linkify("see <arXiv:1802.03967>."),
    "see &lt;<a href='https://arxiv.org/abs/1802.03967'>arXiv:1802.03967</a>&gt;."
  )
  ## unsupported formats are left alone (just escaping special characters)
  unsupported <- c(
    "<doi:10.1002/(SICI)1097-0258(19980930)17:18<2045::AID-SIM943>3.0.CO;2-P>",
    "<https://scholar.google.com/citations?view_op=top_venues&hl=de&vq=phy_probabilitystatistics>"
  )
  expect_identical(linkify(unsupported), escape_html(unsupported))
})
