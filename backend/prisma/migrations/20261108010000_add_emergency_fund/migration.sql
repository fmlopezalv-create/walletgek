-- AlterTable
ALTER TABLE "User" ADD COLUMN     "emergencyFundMonths" INTEGER NOT NULL DEFAULT 3;
ALTER TABLE "User" ADD COLUMN     "emergencyFundSaved" DECIMAL(12,2) NOT NULL DEFAULT 0;
