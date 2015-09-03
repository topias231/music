// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2015 Noise Developers (https://launchpad.net/noise)
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
 */

namespace Noise.Database {
    namespace Tables {
        public const string PLAYLISTS = """CREATE TABLE IF NOT EXISTS playlists (name TEXT, media TEXT,
            sort_column_id INT, sort_direction TEXT, columns TEXT, rowid INTEGER PRIMARY KEY AUTOINCREMENT)""";

        public const string SMART_PLAYLISTS = """CREATE TABLE IF NOT EXISTS smart_playlists (name TEXT,
            and_or INT, queries TEXT, limited INT, limit_amount INT, rowid INTEGER PRIMARY KEY AUTOINCREMENT)""";

        public const string COLUMNS = """CREATE TABLE IF NOT EXISTS columns (unique_id TEXT, sort_column_id INT,
            sort_direction INT, columns TEXT)""";

        public const string MEDIA = """CREATE TABLE IF NOT EXISTS media (uri TEXT, file_size INT,
            title TEXT, artist TEXT, composer TEXT, album_artist TEXT, album TEXT,
            grouping TEXT, genre TEXT, comment TEXT, lyrics TEXT, has_embedded INT,
            year INT, track INT, track_count INT, album_number INT,
            album_count INT, bitrate INT, length INT, samplerate INT, rating INT,
            playcount INT, skipcount INT, dateadded INT, lastplayed INT,
            lastmodified INT, rowid INTEGER PRIMARY KEY AUTOINCREMENT)""";

        public const string DEVICES = """CREATE TABLE IF NOT EXISTS devices (unique_id TEXT,
            sync_when_mounted INT, sync_music INT, sync_all_music INT, music_playlist STRING,
            last_sync_time INT)""";
    }

    /*
     * NOTE:
     * Update those constants when you change the order of columns.
     */
    namespace Playlists {
        public static const string TABLE_NAME = "playlists";
        public static const string NAME = "+0";
        public static const string MEDIA = "+1";
        public static const string SORT_COLUMN_ID = "+2";
        public static const string SORT_DIRECTION = "+3";
        public static const string COLUMNS = "+4";
        public static const string ROWID = "+5";
    }

    namespace SmartPlaylists {
        public static const string TABLE_NAME = "smart_playlists";
        public static const string NAME = "+0";
        public static const string AND_OR = "+1";
        public static const string QUERIES = "+2";
        public static const string LIMITED = "+3";
        public static const string LIMIT_AMOUNT = "+4";
        public static const string ROWID = "+5";
    }

    namespace Media {
        public static const string TABLE_NAME = "media";
        public static const string URI = "+0";
        public static const string FILE_SIZE = "+1";
        public static const string TITLE = "+2";
        public static const string ARTIST = "+3";
        public static const string COMPOSER = "+4";
        public static const string ALBUM_ARTIST = "+5";
        public static const string ALBUM = "+6";
        public static const string GROUPING = "+7";
        public static const string GENRE = "+8";
        public static const string COMMENT = "+9";
        public static const string LYRICS = "+10";
        public static const string HAS_EMBEDDED = "+11";
        public static const string YEAR = "+12";
        public static const string TRACK = "+13";
        public static const string TRACK_COUNT = "+14";
        public static const string ALBUM_NUMBER = "+15";
        public static const string ALBUM_COUNT = "+16";
        public static const string BITRATE = "+17";
        public static const string LENGTH = "+18";
        public static const string SAMPLERATE = "+19";
        public static const string RATING = "+20";
        public static const string PLAYCOUNT = "+21";
        public static const string SKIPCOUNT = "+22";
        public static const string DATEADDED = "+23";
        public static const string LASTPLAYED = "+24";
        public static const string LASTMODIFIED = "+25";
        public static const string ROWID = "+26";
    }

    namespace Devices {
        public static const string TABLE_NAME = "devices";
        public static const string UNIQUE_ID = "+0";
        public static const string SYNC_WHEN_MOUNTED = "+1";
        public static const string SYNC_MUSIC = "+2";
        public static const string SYNC_ALL_MUSIC = "+3";
        public static const string MUSIC_PLAYLIST = "+4";
        public static const string LAST_SYNC_TIME = "+5";
    }

    namespace Columns {
        public static const string TABLE_NAME = "columns";
        public static const string UNIQUE_ID = "+0";
        public static const string SORT_COLUMN_ID = "+1";
        public static const string SORT_DIRECTION = "+2";
        public static const string COLUMNS = "+3";
    }

    /*
     * Helper functions.
     */
    public static Value make_string_value (string str) {
        var val = Value (typeof(string));
        val.set_string (str);
        return val;
    }

    public static Value make_bool_value (bool bl) {
        var val = Value (typeof(bool));
        val.set_boolean (bl);
        return val;
    }

    public static Value make_uint_value (uint u) {
        var val = Value (typeof(uint));
        val.set_uint (u);
        return val;
    }

    public static Value make_int_value (int u) {
        var val = Value (typeof(int));
        val.set_int (u);
        return val;
    }

    public static Value make_int64_value (int64 u) {
        var val = Value (typeof(int64));
        val.set_int64 (u);
        return val;
    }

    public static Value make_uint64_value (uint64 u) {
        var val = Value (typeof(uint64));
        val.set_uint64 (u);
        return val;
    }

    public static GLib.Value? query_field (int64 rowid, Gda.Connection connection, string table, string field) {
        try {
            var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            sql.select_add_target (table, null);
            sql.add_field_value_id (sql.add_id (field), 0);
            var id_field = sql.add_id ("rowid");
            var id_param = sql.add_expr_value (null, Database.make_int64_value (rowid));
            var id_cond = sql.add_cond (Gda.SqlOperatorType.EQ, id_field, id_param, 0);
            sql.set_where (id_cond);
            var data_model = connection.statement_execute_select (sql.get_statement (), null);
            return data_model.get_value_at (data_model.get_column_index (field), 0);
        } catch (Error e) {
            critical ("Could not query field %s: %s", field, e.message);
            return null;
        }
    }

    public static void set_field (int64 rowid, Gda.Connection connection, string table, string field, GLib.Value value) {
        try {
            var rowid_value = GLib.Value (typeof (int64));
            rowid_value.set_int64 (rowid);
            var col_names = new GLib.SList<string> ();
            col_names.append (field);
            var values = new GLib.SList<GLib.Value?> ();
            values.append (value);
            connection.update_row_in_table_v (table, "rowid", rowid_value, col_names, values);
        } catch (Error e) {
            critical ("Could not set field %s: %s", field, e.message);
        }
    }

    public static Gda.SqlBuilderId process_smart_query (Gda.SqlBuilder builder, SmartQuery sq) {
        Value value = Value (sq.value.type ());
        sq.value.copy (ref value);
        string field;
        switch (sq.field) {
            case SmartQuery.FieldType.ALBUM:
                field = "album";
                break;
            case SmartQuery.FieldType.ARTIST:
                field = "artist";
                break;
            case SmartQuery.FieldType.BITRATE:
                field = "bitrate";
                break;
            case SmartQuery.FieldType.COMMENT:
                field = "comment";
                break;
            case SmartQuery.FieldType.COMPOSER:
                field = "composer";
                break;
            case SmartQuery.FieldType.DATE_ADDED:
                // We need the current timestamp because this field is relative.
                value = Value (typeof (int));
                value.set_int ((int)time_t ());
                field = "dateadded";
                break;
            case SmartQuery.FieldType.GENRE:
                field = "genre";
                break;
            case SmartQuery.FieldType.GROUPING:
                field = "grouping";
                break;
            case SmartQuery.FieldType.LAST_PLAYED:
                // We need the current timestamp because this field is relative.
                value = Value (typeof (int));
                value.set_int ((int)time_t ());
                field = "lastplayed";
                break;
            case SmartQuery.FieldType.LENGTH:
                field = "length";
                break;
            case SmartQuery.FieldType.PLAYCOUNT:
                field = "playcount";
                break;
            case SmartQuery.FieldType.RATING:
                field = "rating";
                break;
            case SmartQuery.FieldType.SKIPCOUNT:
                field = "skipcount";
                break;
            case SmartQuery.FieldType.YEAR:
                field = "year";
                break;
            case SmartQuery.FieldType.TITLE:
            default:
                field = "title";
                break;
        }

        Gda.SqlOperatorType sql_operator_type;
        switch (sq.comparator) {
            case SmartQuery.ComparatorType.IS_NOT:
                sql_operator_type = Gda.SqlOperatorType.NOT;
                break;
            case SmartQuery.ComparatorType.CONTAINS:
            case SmartQuery.ComparatorType.NOT_CONTAINS:
                value = make_string_value ("%" + value.get_string () + "%");
                sql_operator_type = Gda.SqlOperatorType.LIKE;
                break;
            case SmartQuery.ComparatorType.IS_EXACTLY:
                sql_operator_type = Gda.SqlOperatorType.EQ;
                break;
            case SmartQuery.ComparatorType.IS_AT_MOST:
                sql_operator_type = Gda.SqlOperatorType.LEQ;
                break;
            case SmartQuery.ComparatorType.IS_AT_LEAST:
                sql_operator_type = Gda.SqlOperatorType.GEQ;
                break;
            case SmartQuery.ComparatorType.IS_WITHIN:
                sql_operator_type = Gda.SqlOperatorType.LEQ;
                break;
            case SmartQuery.ComparatorType.IS_BEFORE:
                sql_operator_type = Gda.SqlOperatorType.GEQ;
                break;
            case SmartQuery.ComparatorType.IS:
            default:
                sql_operator_type = Gda.SqlOperatorType.LIKE;
                break;
        }

        var id_field = builder.add_id (field);
        var id_value = builder.add_expr_value (null, value);
        if (sq.comparator == SmartQuery.ComparatorType.NOT_CONTAINS) {
            var cond = builder.add_cond (sql_operator_type, id_field, id_value, 0);;
            return builder.add_cond (Gda.SqlOperatorType.NOT, cond, 0, 0);
        } else {
            return builder.add_cond (sql_operator_type, id_field, id_value, 0);
        }
    }
}