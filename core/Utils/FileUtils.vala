// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

namespace Noise.FileUtils {

    public const string APP_NAME = "noise"; // TODO: get this info from build system

    public File get_data_directory () {
        string data_dir = Environment.get_user_data_dir ();
        string dir_path = Path.build_path (Path.DIR_SEPARATOR_S, data_dir, APP_NAME);
        return File.new_for_path (dir_path);
    }

    public File get_cache_directory () {
        string data_dir = Environment.get_user_cache_dir ();
        string dir_path = Path.build_path (Path.DIR_SEPARATOR_S, data_dir, APP_NAME);
        return File.new_for_path (dir_path);
    }

    /**
     * Convenience method to get the size of a file or directory (recursively)
     *
     * @param file a {@link GLib.File} representing the file or directory to be queried
     *
     * @return size in bytes of file. It is recommended to use GLib.format_size() in case
     *         you want to convert it to a string representation.
     */
    public uint64 get_size (File file_or_dir, Cancellable? cancellable = null) {
        uint64 size = 0;
        Gee.Collection<File> files;

        if (is_directory (file_or_dir, cancellable)) {
            enumerate_files (file_or_dir, null, true, out files, cancellable);
        } else {
            files = new Gee.LinkedList<File> ();
            files.add (file_or_dir);
        }

        foreach (var file in files) {
            if (Utils.is_cancelled (cancellable))
                break;

            try {
                var info = file.query_info (FileAttribute.STANDARD_SIZE,
                                            FileQueryInfoFlags.NOFOLLOW_SYMLINKS, cancellable);
                size += info.get_attribute_uint64 (FileAttribute.STANDARD_SIZE);
            } catch (Error err) {
                warning ("Could not get size of '%s': %s", file.get_uri (), err.message);
            }
        }

        return size;
    }

    public bool is_directory (File file, Cancellable? cancellable = null) {
        var type = file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS, cancellable);
        return type == FileType.DIRECTORY;
    }

    /**
     * Enumerates the files contained by folder.
     *
     * @param folder a {@link GLib.File} representing the folder you wish to query
     * @param types a string array containing the formats you want to limit the search to, or null
     *              to allow any file type. e.g. [[[string[] types = {"mp3", "jpg"}]]] [allow-none]
     * @param recursive whether to query the whole directory tree or only immediate children. [allow-none]
     * @param files the data container for the files found. This only includes files, not directories [allow-none]
     * @param cancellable a cancellable object for cancelling the operation. [allow-none]
     *
     * @return total number of files found (should be the same as files.size)
     */
    public uint enumerate_files (File folder, string[]? types = null,
                                 bool recursive = true,
                                 out Gee.Collection<File>? files = null,
                                 Cancellable? cancellable = null) {
        return_val_if_fail (is_directory (folder), 0);
        var counter = new FileEnumerator ();
        return counter.enumerate_files (folder, types, out files, recursive, cancellable);
    }

    /**
     * Comprobates whether a filename matches a given extension.
     *
     * @param name path, URI or name of the file to verify
     * @param types a string array containing the expected file extensions (without dot).
     *              e.g. [[[ string[] types = { "png", "m4a", "mp3" }; ]]]
     *
     * @return true if the file is considered valid; false otherwise
     */
	public bool is_valid_file_type (string filename, string[] types) {
		var name = filename.down ();

        foreach (var suffix in types) {
            if (name.has_suffix ("." + suffix.down ()))
                return true;
        }

        return false;
	}

    /**
     * A class for counting the number of files contained by a directory, without
     * counting folders.
     */
    private class FileEnumerator {
        private uint file_count = 0;
        private const string ATTRIBUTES = FileAttribute.STANDARD_NAME
                                            + "," + FileAttribute.STANDARD_TYPE;
        private string[]? types = null;
        private Cancellable? cancellable = null;

        /**
         * Enumerates the number of files contained by a directory. By default it
         * operates recursively; that is, it will count all the files contained by
         * the directories descendant from folder. In case you only want the first-level
         * descendants, set recursive to false.
         */
        public uint enumerate_files (File folder, string[]? types,
                                     out Gee.Collection<File>? files,
                                     bool recursive = true,
                                     Cancellable? cancellable = null) {
            assert (file_count == 0);

            this.types = types;
            this.cancellable = cancellable;

            files = new Gee.LinkedList<File> ();
            enumerate_files_internal (folder, ref files, recursive);
            return file_count;
        }

        private inline bool is_cancelled () {
            return Utils.is_cancelled (cancellable);
        }

        private void enumerate_files_internal (File folder, ref Gee.Collection<File>? files,
            bool recursive) {

            if (is_cancelled ())
                return;

            try {
                var enumerator = folder.enumerate_children (ATTRIBUTES,
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS, cancellable);

                FileInfo? file_info = null;

                while ((file_info = enumerator.next_file ()) != null && !is_cancelled ()) {
                    var file_name = file_info.get_name ();
                    var file_type = file_info.get_file_type ();
                    var file = folder.get_child (file_name);

                    if (file_type == FileType.REGULAR) {
                        if (this.types != null && !is_valid_file_type (file_name, this.types))
                            continue;

	                    file_count++;
                        if (files != null)
    	                    files.add (file);
                    }
                    else if (recursive && file_type == FileType.DIRECTORY) {
	                    enumerate_files_internal (file, ref files, true);
                    }
                }
            }
            catch (Error err) {
                warning ("Could not scan folder: %s", err.message);
            }
        }
    }
}