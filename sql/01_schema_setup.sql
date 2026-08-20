-- Phase 1: Database Setup & Staging Configuration

CREATE DATABASE IF NOT EXISTS dataco_supply_chain;
USE dataco_supply_chain;

-- The raw data is imported into raw_dataco_orders via MySQL Workbench Import Wizard.
-- Total raw expected records: 180,519
-- Total staging imported records: 180,516