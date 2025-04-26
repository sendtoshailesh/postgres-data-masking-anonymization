# PostgreSQL Anonymizer Documentation

This repository contains comprehensive documentation for using PostgreSQL Anonymizer, a powerful extension for masking and anonymizing sensitive data in PostgreSQL databases.

• Step-by-step implementation of multiple anonymization techniques 

• Practical examples of masking views, dynamic masking, and pseudonymization 

• Real-world case studies from healthcare and financial sectors 

• Performance optimization strategies 

• Advanced features including differential privacy and data synthesis

With data breaches costing an average of $4.45M in 2023, protecting sensitive data while maintaining its utility is crucial. This guide provides practical solutions for:

GDPR, HIPAA, and CCPA compliance
Secure development/testing environments
Safe data sharing with third parties
Privacy-preserving analytics

## Table of Contents

1. [Setup and Installation](01_setup_docker.md)
   - Docker installation and setup
   - Connection information
   - Container management

2. [Sample Data Creation](02_sample_data_creation.md)
   - Creating tables with sensitive data
   - Sample data for different scenarios
   - Test data generation

3. [Anonymization Functions](03_anonymization_functions.md)
   - Basic anonymization functions
   - Partial data masking
   - Randomization functions
   - Pseudonymization functions
   - Generalization functions
   - Noise addition
   - Dummy data generation
   - Text masking

4. [Masking Techniques](04_masking_techniques.md)
   - Masking views
   - Dynamic masking with security labels
   - Static masking
   - Anonymous dumps
   - Pseudonymization
   - K-anonymity

5. [Role-Based Access Control](05_role_based_access.md)
   - Creating roles with different access levels
   - Granting permissions
   - Implementing dynamic masking
   - Creating role-specific views
   - Using materialized views
   - Testing access control

6. [Data Export and Import](06_data_export_import.md)
   - Exporting anonymized data
   - Importing anonymized data
   - Creating anonymized copies
   - Scheduled exports
   - Data transfer between environments
   - Selective data export

7. [Best Practices](07_best_practices.md)
   - Planning your anonymization strategy
   - Implementation best practices
   - Security considerations
   - Performance optimization
   - Monitoring and maintenance

8. [Troubleshooting](08_troubleshooting.md)
   - Installation issues
   - Permission issues
   - Function errors
   - Performance issues
   - Docker-specific issues
   - Debugging tips

9. [Advanced Anonymization Techniques](09_advanced_anonymization_techniques.md)
   - Detailed pseudonymization implementation
   - K-anonymity for statistical data
   - L-diversity and T-closeness
   - Security labels explained
   - Cross-table anonymization

10. [Blog Post: Securing Sensitive Data in PostgreSQL](10_blog_post.md)
    - Comprehensive guide to data anonymization
    - Real-world case studies
    - Implementation examples
    - Visual diagrams and explanations

## Quick Start

1. Start the PostgreSQL Anonymizer Docker container:
   ```bash
   docker run -d --name pg-anon -e POSTGRES_PASSWORD=mysecretpassword -p 5433:5432 registry.gitlab.com/dalibo/postgresql_anonymizer:stable
   ```

2. Connect to the database:
   ```bash
   PGPASSWORD=mysecretpassword psql -h localhost -p 5433 -U postgres -d postgres
   ```

3. Initialize the extension:
   ```sql
   SELECT anon.init();
   ```

4. Test a basic anonymization function:
   ```sql
   SELECT anon.partial_email('john.doe@example.com');
   ```

## Additional Resources

- [Official PostgreSQL Anonymizer Documentation](https://postgresql-anonymizer.readthedocs.io/)
- [PostgreSQL Anonymizer GitHub Repository](https://gitlab.com/dalibo/postgresql_anonymizer)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## License

This documentation is provided under the MIT License. The PostgreSQL Anonymizer extension is licensed under the PostgreSQL License.

## Contributing

Contributions to improve this documentation are welcome. Please submit pull requests or open issues to suggest improvements or report errors.

## Quick Start

1. Start the PostgreSQL Anonymizer Docker container:
   ```bash
   docker run -d --name pg-anon -e POSTGRES_PASSWORD=mysecretpassword -p 5433:5432 registry.gitlab.com/dalibo/postgresql_anonymizer:stable
   ```

2. Connect to the database:
   ```bash
   PGPASSWORD=mysecretpassword psql -h localhost -p 5433 -U postgres -d postgres
   ```

3. Initialize the extension:
   ```sql
   SELECT anon.init();
   ```

4. Test a basic anonymization function:
   ```sql
   SELECT anon.partial_email('john.doe@example.com');
   ```

## Additional Resources

- [Official PostgreSQL Anonymizer Documentation](https://postgresql-anonymizer.readthedocs.io/)
- [PostgreSQL Anonymizer GitHub Repository](https://gitlab.com/dalibo/postgresql_anonymizer)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## License

This documentation is provided under the MIT License. The PostgreSQL Anonymizer extension is licensed under the PostgreSQL License.

## Contributing

Contributions to improve this documentation are welcome. Please submit pull requests or open issues to suggest improvements or report errors.
