#' Upload a file to Drive.
#'
#' @seealso MIME types that can be converted to native Google formats:
#'    * <https://developers.google.com/drive/v3/web/manage-uploads#importing_to_google_docs_types_wzxhzdk18wzxhzdk19>
#'
#' @param file Character, path to the local file to upload.
#' @template path
#' @param name Character, name the file should have on Google Drive if not
#'   specified in `path`. Will default to its local name.
#' @param overwrite A logical scalar, do you want to overwrite a file already on
#'   Google Drive, if such exists?
#' @param type Character. If type = `NULL`, a MIME type is automatically
#'   determined from the file extension, if possible. If the source file is of a
#'   suitable type, you can request conversion to Google Doc, Sheet or Slides by
#'   setting `type` to `document`, `spreadsheet`, or `presentation`,
#'   respectively. All non-`NULL` values for `type` are pre-processed with
#'   [drive_mime_type()].
#' @template verbose
#'
#' @template dribble-return
#' @export
#' @examples
#' \dontrun{
#' ## upload a csv file
#' mirrors_csv <- drive_upload(R.home('doc/BioC_mirrors.csv'))
#'
#' ## or convert it to a Google Sheet
#' mirrors_sheet <- drive_upload(
#'   R.home('doc/BioC_mirrors.csv'),
#'   name = "BioC_mirrors",
#'   type = "spreadsheet"
#' )
#'
#' ## check out the new Sheet!
#' drive_browse(mirrors_sheet)
#'
#' ## clean-up
#' drive_search("BioC_mirrors") %>% drive_delete()
#' }
drive_upload <- function(file = NULL,
                         path = NULL,
                         name = NULL,
                         overwrite = FALSE,
                         type = NULL,
                         verbose = TRUE) {

  if (!file.exists(file)) {
    stop(glue("File does not exist:\n{file}"), call. = FALSE)
  }

  if (!is.null(name)) {
    stopifnot(is_path(name), length(name) == 1)
  }

  if (is_path(path)) {
    if (is.null(name) && drive_path_exists(append_slash(path))) {
      path <- append_slash(path)
    }
    path_parts <- partition_path(path, maybe_name = is.null(name))
    path <- path_parts$parent
    name <- name %||% path_parts$name
  }

  ## vet the parent folder
  ## easier to default to root vs keeping track of whether parent is specified
  path <- path %||% root_folder()
  path <- as_dribble(path)
  confirm_single_file(path)
  if (!is_folder(path)) {
    stop(
      glue(
        "Requested parent folder does not exist:\n{path$name}"
      ),
      call. = FALSE
    )
  }

  name <- name %||% basename(file)
  mimeType <- drive_mime_type(type)

  ## is there a pre-existing file at destination?
  q_name <- glue("name = {sq(name)}")
  q_parent <- glue("{sq(path$id)} in parents")
  qq <- collapse(c(q_name, q_parent), sep = " and ")
  existing <- drive_search(q = qq)

  if (nrow(existing) > 0) {
    out_path <- unsplit_path(path$name %||% "", name)
    if (!overwrite) {
      stop(glue("Path already exists:\n{out_path}", call. = FALSE))
    }
    if (nrow(existing) > 1) {
      stop(glue("Path to overwrite is not unique:\n{out_path}", call. = FALSE))
    }
  }
  ## id for the uploaded file
  up_id <- existing$id

  if (length(up_id) == 0) {
    request <- generate_request(
      endpoint = "drive.files.create",
      params = list(
        name = name,
        parents = list(path$id),
        mimeType = mimeType
      )
    )

    response <- make_request(request, encode = "json")
    proc_res <- process_response(response)
    up_id <- proc_res$id
  }

  request <- generate_request(
    endpoint = "drive.files.update.media",
    params = list(fileId = up_id,
                  uploadType = "media",
                  fields = "*")
  )

  ## media uploads have unique body situations, so customizing here.
  request$body <- httr::upload_file(
    path = file,
    type = mimeType
  )

  response <- make_request(request, encode = "json")
  proc_res <- process_response(response)

  uploaded_doc <- as_dribble(list(proc_res))
  ## TO DO: this is a pretty weak test for success...
  success <- proc_res$id == uploaded_doc$id[1]

  if (success) {
    if (verbose) {
      message(
        glue("\nFile uploaded:\n  * {proc_res$name}\n",
             "with MIME type:\n  * {proc_res$mimeType}")
      )
    }
  } else {
    stop("The file doesn't seem to have uploaded.", call. = FALSE)
  }

  invisible(uploaded_doc)
}
