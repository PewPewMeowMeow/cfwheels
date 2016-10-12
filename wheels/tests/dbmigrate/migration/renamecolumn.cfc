component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.dbmigrate.Migration").init();
	}

	function test_renameColumn_renames_column() {
		tableName = "dbm_renamecolumn_tests";
		oldColumnName = "oldcolumn";
		newColumnName = "newcolumn";
		t = migration.createTable(name=tableName, force=true);
		t.string(columnNames=oldColumnName);
		t.create();
		migration.renameColumn(table=tableName, columnName=oldColumnName, newColumnName=newColumnName);

		actual = model(tableName).findAll().columnList;
		expected = newColumnName;
		assert("ListFindNoCase(actual, expected)");
	}

}
