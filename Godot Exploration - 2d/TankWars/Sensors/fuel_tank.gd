extends Node2D
class_name FuelTank

signal fuel_low
signal fuel_full

var fuelLevel: int = 100
@onready var behavior: StateChart = $Behavior

func _ready() -> void:
	self.behavior.set_expression_property.call_deferred("fuelLevel", self.fuelLevel)

func update_fuel_level(amount: int) -> void:
	self.fuelLevel += amount
	self.behavior.set_expression_property("fuelLevel", self.fuelLevel)


func _on_fuel_low_taken() -> void:
	self.fuel_low.emit()


func _on_fuel_full_taken() -> void:
	self.fuel_full.emit()
