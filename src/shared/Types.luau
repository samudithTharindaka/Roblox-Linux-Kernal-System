--!strict
-- Types.luau
-- Shared type definitions for LinuxOS Simulator

export type Permission = {
	read: boolean,
	write: boolean,
	execute: boolean,
}

export type FileMetadata = {
	name: string,
	isDirectory: boolean,
	owner: string,
	permissions: Permission,
	timestamp: number,
	size: number,
	content: string?,
	executable: boolean,
}

export type Directory = {
	[string]: FileMetadata | Directory,
}

export type VFSNode = {
	metadata: FileMetadata,
	children: { [string]: VFSNode }?,
}

export type Process = {
	pid: number,
	name: string,
	owner: string,
	cpuUsage: number,
	memoryUsage: number,
	status: "running" | "sleeping" | "stopped" | "zombie",
	startTime: number,
	command: string,
}

export type Service = {
	port: number,
	name: string,
	owner: string,
	handler: string,
	version: string,
	isPublic: boolean,
}

export type NetworkConnection = {
	sourceIP: string,
	destinationIP: string,
	sourcePort: number,
	destinationPort: number,
	protocol: "TCP" | "UDP",
	status: "ESTABLISHED" | "LISTENING" | "CLOSED",
}

export type AuditLogEntry = {
	timestamp: number,
	user: string,
	action: string,
	details: string,
	severity: "info" | "warning" | "critical",
	sourceIP: string?,
}

export type User = {
	username: string,
	uid: number,
	groups: { string },
	homeDirectory: string,
	passwordHash: string,
	sudoEnabled: boolean,
}

export type FirewallRule = {
	port: number,
	action: "allow" | "deny",
	protocol: "TCP" | "UDP" | "both",
}

export type CommandResult = {
	success: boolean,
	output: string,
	errorCode: number?,
}

export type Snapshot = {
	name: string,
	timestamp: number,
	vfsData: any,
}

export type PlayerState = {
	currentUser: string,
	currentDirectory: string,
	ipAddress: string,
	vmUptime: number,
	commandHistory: { string },
	environment: { [string]: string },
}

export type ExploitDefinition = {
	name: string,
	targetService: string,
	targetVersion: string,
	successRate: number,
	requiredSkill: number,
	noiseLevel: number,
}

export type Payload = {
	name: string,
	type: "backdoor" | "worm" | "trojan" | "keylogger",
	size: number,
	signature: string,
	content: string,
}

return {}

