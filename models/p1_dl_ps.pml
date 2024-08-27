#define N 2 // number of instances

mtype = { acquire, release }; // requests
mtype = { succeeded, failed }; // responses. no response for release.

chan lock_req[N] = [2] of { mtype };  // 1: acquire, 0: release
chan lock_resp[N] = [2] of { mtype };  // 1: acquired, 0: not-acquired

mtype = { disconnect };
chan ps = [1] of {mtype}; // primary-secondary connection

bool isPrimaryLeader = false;
bool isPrimaryActive = false;
bool isSecondaryLeader = false;
bool isSecondaryActive = false;

bool isPrimaryDead = false;


proctype primary(int id) {

S0: // startup.
    lock_req[id]!acquire;  // acquire lock
    if
    :: lock_resp[id]?succeeded -> goto S1;
    :: lock_resp[id]?failed -> goto S_END;
    fi

S1: // working state
    isPrimaryLeader = true;
    isPrimaryActive = true;
    do
    :: lock_req[id]!acquire; // extend lock
    :: lock_resp[id]?succeeded ->
       isPrimaryActive = true;
    :: lock_resp[id]?failed ->
       isPrimaryActive = false;
    :: isPrimaryActive; // do work
    od

S_END:
    isPrimaryLeader = false;
    isPrimaryActive = false;
    isPrimaryDead = true;
}

proctype secondary(int id) {

S0: // triggered by primary's death
    isPrimaryDead ->
        lock_req[id]!acquire; // acquire lock

    if
    :: lock_resp[id]?succeeded ->
       skip;
    :: lock_resp[id]?failed ->
       isSecondaryLeader = false;
       isSecondaryActive = false;
       goto S0;
    fi

S1: // Become leader
    isSecondaryLeader = true;
    isSecondaryActive = true;

    do
    :: lock_req[id]!acquire; // extend lock
    :: lock_resp[id]?succeeded ->
       isSecondaryActive = true;
    :: lock_resp[id]?failed ->
       isSecondaryActive = false;
    :: isSecondaryActive ->
       skip;  // do work
    od

S_END:
    isSecondaryLeader = false;
    isSecondaryActive = false;
}


proctype lock_server() {
bool locked = false;
bit owner = 0;

    do
    :: atomic {lock_req[0]?acquire ->
       if
       :: (!locked || (owner==0)) ->
          lock_resp[0]!succeeded;
          locked = true;
          owner = 0;
       :: else ->
          lock_resp[0]!failed;
       fi}

    :: atomic {lock_req[1]?acquire ->
       if
       :: (!locked || (owner==0)) ->
          lock_resp[1]!succeeded;
          locked = true;
          owner = 1;
       :: else ->
          lock_resp[0]!failed;
       fi}

    od
}

init {

run lock_server()

run primary(0)
run secondary(1)

}
