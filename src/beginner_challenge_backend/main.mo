import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import Vector "mo:vector";
import {phash; nhash} "mo:map/Map";


actor {

    stable var nextId : Nat = 0;
    stable var userIdMap : Map.Map<Principal, Nat> = Map.new<Principal, Nat>();
    stable var userProfileMap : Map.Map<Nat, Text> = Map.new<Nat, Text>();
    stable var userResultMap : Map.Map<Nat, Vector.Vector<Text>> = Map.new<Nat, Vector.Vector<Text>>();

    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        let userId = switch (Map.get(userIdMap, phash, caller)) {
            case(?found) found;
            case (_) return #err("User not found");
        };

        let name = switch (Map.get(userProfileMap, nhash, userId)) {
            case (?found) found;
            case (_) return #err("User name not found");
        };

        return #ok({id = userId; name = name});
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        Debug.print(debug_show caller);
        var idRecorded = 0;
        switch(Map.get(userIdMap, phash, caller)) {
            case(?idFound) {
                Map.set(userIdMap, phash, caller, idFound);
                Map.set(userProfileMap, nhash, idFound, name);
                idRecorded := idFound;
            };

            case(_) {
                Map.set(userIdMap, phash, caller, nextId);
                Map.set(userProfileMap, nhash, nextId, name);
                idRecorded := nextId;
                nextId += 1
            };
        };

        return #ok({id = idRecorded; name = name});
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userId = switch (Map.get(userIdMap, phash, caller)) {
            case(?found) found;
            case (_) return #err("User not found");
        };

        let results = switch (Map.get(userResultMap, nhash, userId)) {
            case (?found) found;
            case (_) Vector.new<Text>();
        };

        Vector.add(results, result);
        Map.set(userResultMap, nhash, userId, results);

        return #ok({id = userId; results = Vector.toArray(results) });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userId = switch (Map.get(userIdMap, phash, caller)) {
            case(?found) found;
            case (_) return #err("User not found");
        };

        let results = switch (Map.get(userResultMap, nhash, userId)) {
            case (?found) found;
            case (_) Vector.new<Text>();
        };

        return #ok({id = userId; results = Vector.toArray(results)});
    };
};
