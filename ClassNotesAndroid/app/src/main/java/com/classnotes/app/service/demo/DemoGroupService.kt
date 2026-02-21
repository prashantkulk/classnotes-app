package com.classnotes.app.service.demo

import com.classnotes.app.model.ClassGroup
import com.classnotes.app.model.SubjectInfo
import com.classnotes.app.service.GroupService
import kotlinx.coroutines.delay

class DemoGroupService : GroupService() {
    override fun loadGroups(userId: String) {
        _groups.value = DemoData.groups
    }

    override suspend fun createGroup(group: ClassGroup): ClassGroup {
        delay(300)
        val newGroup = group.copy(members = listOf(group.createdBy))
        val current = _groups.value.toMutableList()
        current.add(0, newGroup)
        _groups.value = current
        return newGroup
    }

    override suspend fun joinGroup(code: String, userId: String): ClassGroup {
        delay(300)
        val group = DemoData.groups.find { it.inviteCode == code }
            ?: throw Exception("No group found with this code. Try: DEMO01")

        if (group.members.contains(userId) || _groups.value.any { it.id == group.id }) {
            throw Exception("You are already a member of ${group.name}.")
        }

        val joined = group.copy(members = group.members + userId)
        val current = _groups.value.toMutableList()
        current.add(0, joined)
        _groups.value = current
        return joined
    }

    override suspend fun leaveGroup(groupId: String, userId: String) {
        delay(300)
        _groups.value = _groups.value.filter { it.id != groupId }
    }

    override suspend fun deleteGroup(group: ClassGroup) {
        delay(300)
        _groups.value = _groups.value.filter { it.id != group.id }
    }

    override suspend fun addCustomSubject(groupId: String, subject: SubjectInfo) {
        delay(300)
        val current = _groups.value.toMutableList()
        val index = current.indexOfFirst { it.id == groupId }
        if (index >= 0) {
            current[index] = current[index].copy(
                customSubjects = current[index].customSubjects + subject.firestoreDict
            )
            _groups.value = current
        }
    }
}
