import datetime
from typing import List, Dict, Any
from mrz.checker.td1 import TD1CodeChecker
from mrz.checker.td2 import TD2CodeChecker
from mrz.checker.td3 import TD3CodeChecker

class MRZService:
    def parse_and_validate(self, mrz_lines: List[str]) -> Dict[str, Any]:
        """Auto-detect format (TD1/TD2/TD3) and validate all checksums."""
        if not mrz_lines:
            return {
                "is_valid": False,
                "format": None,
                "checksums_passed": False,
                "warnings": ["Non-travel document (No MRZ zone)"]
            }

        mrz_string = "\n".join(mrz_lines)
        num_lines = len(mrz_lines)
        line_len = len(mrz_lines[0]) if num_lines > 0 else 0

        checker = None
        format_type = None

        try:
            if num_lines == 3 and line_len == 30:
                checker = TD1CodeChecker(mrz_string)
                format_type = "TD1"
            elif num_lines == 2 and line_len == 36:
                checker = TD2CodeChecker(mrz_string)
                format_type = "TD2"
            elif num_lines == 2 and line_len == 44:
                checker = TD3CodeChecker(mrz_string)
                format_type = "TD3"
            else:
                return {
                    "is_valid": False, 
                    "format": None,
                    "checksums_passed": False,
                    "warnings": ["MRZ format dimensions not recognized"]
                }
            
            fields = checker.fields()
            is_valid = bool(checker)
            
            return {
                "is_valid": True,
                "format": format_type,
                "document_number": fields.document_number,
                "nationality": fields.nationality,
                "birth_date": fields.birth_date,
                "expiry_date": fields.expiry_date,
                "sex": fields.sex,
                "surname": fields.surname,
                "names": fields.name,
                "checksums_passed": is_valid,
                "warnings": [] if is_valid else ["Checksums failed for MRZ"]
            }
        except Exception as e:
            return {"is_valid": False, "warnings": [f"Error parsing MRZ: {str(e)}"]}

    def cross_validate_viz_mrz(self, viz_fields: Dict[str, str], mrz_fields: Dict[str, Any]) -> Dict[str, Any]:
        """Compare OCR-extracted VIZ text vs MRZ-parsed fields."""
        if not mrz_fields.get("is_valid"):
            return {"mrz_viz_match": None, "details": "MRZ invalid"}
            
        mismatch_found = False
        details = []
        
        # Simple fuzzy/exact matching can be added here
        if "name" in viz_fields and mrz_fields.get("names"):
            if viz_fields["name"].upper().replace(" ", "") != mrz_fields["names"].upper().replace(" ", ""):
                mismatch_found = True
                details.append("Name mismatch between VIZ and MRZ")
                
        return {
            "mrz_viz_match": not mismatch_found,
            "details": details
        }

    def check_expiry(self, expiry_date_str: str) -> bool:
        """Check if document is expired. (Format generally YYMMDD)"""
        if not expiry_date_str or len(expiry_date_str) != 6:
            return False
            
        try:
            # Simple assumption: YY < 50 is 2000s, else 1900s
            year = int(expiry_date_str[0:2])
            month = int(expiry_date_str[2:4])
            day = int(expiry_date_str[4:6])
            
            full_year = 2000 + year if year < 50 else 1900 + year
            expiry = datetime.date(full_year, month, day)
            return expiry < datetime.date.today()
        except ValueError:
            return False
