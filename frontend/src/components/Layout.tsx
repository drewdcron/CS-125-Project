import React from 'react';
import { Outlet, Link } from 'react-router-dom';
import { Navbar, Container, Nav } from 'react-bootstrap';

const Layout: React.FC = () => {
  return (
    <div className="App">
      <Navbar expand="lg" className="navbar-custom" variant="dark">
        <Container fluid>
          <Navbar.Brand as={Link} to="/">YGMS Event Manager</Navbar.Brand>
          <Navbar.Toggle aria-controls="basic-navbar-nav" />
          <Navbar.Collapse id="basic-navbar-nav">
            <Nav className="me-auto">
              <Nav.Link as={Link} to="/">Events</Nav.Link>
              <Nav.Link as={Link} to="/events/new">Create Event</Nav.Link>
            </Nav>
          </Navbar.Collapse>
        </Container>
      </Navbar>

      <main className="main-content">
        <Container fluid>
          <Outlet />
        </Container>
      </main>

      <footer className="footer">
        <Container fluid className="text-center">
          <p>&copy; {new Date().getFullYear()} Youth Group Management System</p>
        </Container>
      </footer>
    </div>
  );
};

export default Layout;
