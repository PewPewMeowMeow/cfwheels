<cfscript>
/**
* Sets up a belongsTo association between this model and the specified one.
* Use this association when this model contains a foreign key referencing another model.
*
* [section: Model Initialization]
* [category: Association Functions]
*
* @name Gives the association a name that you refer to when working with the association (in the include argument to findAll, to name one example).
* @modelName Name of associated model (usually not needed if you follow CFWheels conventions because the model name will be deduced from the name argument).
* @foreignKey Foreign key property name (usually not needed if you follow CFWheels conventions since the foreign key name will be deduced from the name argument).
* @joinKey Column name to join to if not the primary key (usually not needed if you follow wheels conventions since the join key will be the tables primary key/keys).
* @joinType inner Use to set the join type when joining associated tables. Possible values are inner (for INNER JOIN) and outer (for LEFT OUTER JOIN).
*/
public void function belongsTo(
	required string name,
	string modelName="",
	string foreignKey="",
	string joinKey="",
	string joinType
) {
	$args(name="belongsTo", args=arguments);
	arguments.type = "belongsTo";

	// The dynamic shortcut methods to add to this class (e.g. "post" , "hasPost").
	arguments.methods = "";
	arguments.methods = ListAppend(arguments.methods, arguments.name);
	arguments.methods = ListAppend(arguments.methods, "has#capitalize(arguments.name)#");

	$registerAssociation(argumentCollection=arguments);
}

/**
* Sets up a hasMany association between this model and the specified one.
*
* [section: Model Initialization]
* [category: Association Functions]
*
* @name Gives the association a name that you refer to when working with the association (in the include argument to findAll, to name one example).
* @modelName Name of associated model (usually not needed if you follow CFWheels conventions because the model name will be deduced from the name argument).
* @foreignKey Foreign key property name (usually not needed if you follow CFWheels conventions since the foreign key name will be deduced from the name argument).
* @joinKey Column name to join to if not the primary key (usually not needed if you follow wheels conventions since the join key will be the tables primary key/keys).
* @joinType Use to set the join type when joining associated tables. Possible values are inner (for INNER JOIN) and outer (for LEFT OUTER JOIN).
* @dependent Defines how to handle dependent models when you delete a record from this model. Set to delete to instantiate associated models and call their delete method, deleteAll to delete without instantiating, removeAll to remove the foreign key, or false to do nothing.
* @shortcut Set this argument to create an additional dynamic method that gets the object(s) from the other side of a many-to-many association.
* @through Set this argument if you need to override CFWheels conventions when using the shortcut argument. Accepts a list of two association names representing the chain from the opposite side of the many-to-many relationship to this model.
*/
public void function hasMany(
	required string name,
	string modelName="",
	string foreignKey="",
	string joinKey="",
	string joinType,
	string dependent,
	string shortcut="",
	string through="#singularize(arguments.shortcut)#,#arguments.name#"
) {
	$args(name="hasMany", args=arguments);
	local.singularizedName = capitalize(singularize(arguments.name));
	local.capitalizedName = capitalize(arguments.name);
	arguments.type = "hasMany";

	// The dynamic shortcut methods to add to this class (e.g. "comment", "commentCount", "addComment" etc).
	arguments.methods = "";
	arguments.methods = ListAppend(arguments.methods, arguments.name);
	arguments.methods = ListAppend(arguments.methods, "#local.singularizedName#Count");
	arguments.methods = ListAppend(arguments.methods, "add#local.singularizedName#");
	arguments.methods = ListAppend(arguments.methods, "create#local.singularizedName#");
	arguments.methods = ListAppend(arguments.methods, "delete#local.singularizedName#");
	arguments.methods = ListAppend(arguments.methods, "deleteAll#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "findOne#local.singularizedName#");
	arguments.methods = ListAppend(arguments.methods, "has#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "new#local.singularizedName#");
	arguments.methods = ListAppend(arguments.methods, "remove#local.singularizedName#");
	arguments.methods = ListAppend(arguments.methods, "removeAll#local.capitalizedName#");

	$registerAssociation(argumentCollection=arguments);
}

/**
* Sets up a hasOne association between this model and the specified one.
*
* [section: Model Initialization]
* [category: Association Functions]
*
* @name string true See documentation for belongsTo.
* @modelName string false See documentation for belongsTo.
* @foreignKey string false See documentation for belongsTo.
* @joinKey string false See documentation for belongsTo.
* @joinType string false outer See documentation for belongsTo.
* @dependent string false false See documentation for hasMany.
*/
public void function hasOne(
	required string name,
	string modelName="",
	string foreignKey="",
	string joinKey="",
	string joinType,
	string dependent
) {
	$args(name="hasOne", args=arguments);
	local.capitalizedName = capitalize(arguments.name);
	arguments.type = "hasOne";

	// The dynamic shortcut methods to add to this class (e.g. "profile", "createProfile", "deleteProfile" etc).
	arguments.methods = "";
	arguments.methods = ListAppend(arguments.methods, arguments.name);
	arguments.methods = ListAppend(arguments.methods, "create#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "delete#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "has#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "new#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "remove#local.capitalizedName#");
	arguments.methods = ListAppend(arguments.methods, "set#local.capitalizedName#");

	$registerAssociation(argumentCollection=arguments);
}

/*
 * Internal function.
 * Registers the association info in the model object on the application scope.
 */
public void function $registerAssociation() {

	// Assign the name for the association.
	local.associationName = arguments.name;

	// Default our nesting to false and set other nesting properties.
	arguments.nested = {};
	arguments.nested.allow = false;
	arguments.nested.delete = false;
	arguments.nested.autosave = false;
	arguments.nested.sortProperty = "";
	arguments.nested.rejectIfBlank = "";

	// Infer model name from association name unless developer specified it already.
	if (!Len(arguments.modelName)) {
		if (arguments.type == "hasMany") {
			arguments.modelName = singularize(local.associationName);
		} else {
			arguments.modelName = local.associationName;
		}
	}

	// Set pluralized association name, to be used when aliasing the table.
	arguments.pluralizedName = pluralize(local.associationName);

	// Store all the settings for the association in the class data.
	// One struct per association with the name of the association as the key.
	// We delete the name from the arguments because we use it as the key and don't need to store it elsewhere.
	StructDelete(arguments, "name");
	variables.wheels.class.associations[local.associationName] = arguments;
}

/*
 * Internal function.
 * Called when a model object is deleted (e.g. post.delete()).
 * Deletes all associated records (or sets their foreign key values to NULL).
 */
public void function $deleteDependents() {
	for (local.key in variables.wheels.class.associations) {
		local.association = variables.wheels.class.associations[local.key];
		if (ListFindNoCase("hasMany,hasOne", local.association.type) && local.association.dependent != false) {
			local.all = "";
			if (local.association.type == "hasMany") {
				local.all = "All";
			}
			switch (local.association.dependent) {
				case "delete":
					local.invokeArgs = {};
					local.invokeArgs.instantiate = true;
					$invoke(componentReference=this, method="delete#local.all##local.key#", invokeArgs=local.invokeArgs);
					break;
				case "remove":
					local.invokeArgs = {};
					local.invokeArgs.instantiate = true;
					$invoke(componentReference=this, method="remove#local.all##local.key#", invokeArgs=local.invokeArgs);
					break;
				case "deleteAll":
					$invoke(componentReference=this, method="delete#local.all##local.key#");
					break;
				case "removeAll":
					$invoke(componentReference=this, method="remove#local.all##local.key#");
					break;
				default:
					Throw(
						type="Wheels.InvalidArgument",
						message="'#local.association.dependent#' is not a valid dependency.",
						extendedInfo="Use `delete`, `deleteAll`, `remove`, `removeAll` or `false`."
					);
			}
		}
	}
}

</cfscript>
